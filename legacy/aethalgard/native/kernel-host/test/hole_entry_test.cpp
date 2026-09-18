// Unit test for the hole entry-point classifier. Builds bodies directly in
// OCCT so it can construct the ONE case the kernel protocol cannot: a body with
// a loose face (a healed/imported artifact) far from the drilling entry point.
// Proves the ON-acceptance band is scoped to the local entry face, so a loose
// face elsewhere never admits an origin off the actual entry surface.
#include <cmath>
#include <cstdio>
#include <stdexcept>
#include <string>

#include <BRepBndLib.hxx>
#include <BRepPrimAPI_MakeBox.hxx>
#include <BRep_Builder.hxx>
#include <BRep_Tool.hxx>
#include <Bnd_Box.hxx>
#include <Precision.hxx>
#include <TopExp_Explorer.hxx>
#include <TopoDS.hxx>
#include <TopoDS_Face.hxx>
#include <TopoDS_Shape.hxx>
#include <TopoDS_Solid.hxx>
#include <gp_Ax2.hxx>
#include <gp_Dir.hxx>
#include <gp_Pnt.hxx>

#include "hole_entry.hpp"

namespace {

int g_failures = 0;

void check(bool condition, const std::string& label) {
  if (condition) {
    std::printf("  ok   %s\n", label.c_str());
  } else {
    std::printf("  FAIL %s\n", label.c_str());
    g_failures += 1;
  }
}

void expectAccepts(const TopoDS_Shape& target, const gp_Ax2& frame, const std::string& label) {
  try {
    aeth::ClassifyHoleEntry(target, frame);
    check(true, label);
  } catch (const std::exception& error) {
    std::printf("  FAIL %s (threw: %s)\n", label.c_str(), error.what());
    g_failures += 1;
  }
}

void expectRejects(const TopoDS_Shape& target, const gp_Ax2& frame, const std::string& label) {
  try {
    aeth::ClassifyHoleEntry(target, frame);
    std::printf("  FAIL %s (accepted, expected rejection)\n", label.c_str());
    g_failures += 1;
  } catch (const std::invalid_argument&) {
    check(true, label);
  }
}

// Returns the single planar box face whose bounding box is flat at z == level.
TopoDS_Face faceAtZ(const TopoDS_Shape& shape, double level) {
  for (TopExp_Explorer it(shape, TopAbs_FACE); it.More(); it.Next()) {
    const TopoDS_Face face = TopoDS::Face(it.Current());
    Bnd_Box box;
    BRepBndLib::Add(face, box);
    double xmin;
    double ymin;
    double zmin;
    double xmax;
    double ymax;
    double zmax;
    box.Get(xmin, ymin, zmin, xmax, ymax, zmax);
    if (std::abs(zmin - level) < 1.0e-6 && std::abs(zmax - level) < 1.0e-6) {
      return face;
    }
  }
  throw std::runtime_error("no box face at the requested z level");
}

} // namespace

int main() {
  // A 40 x 40 x 20 box occupying [0,40] x [0,40] x [0,20]. Top face z = 20.
  BRepPrimAPI_MakeBox maker(40.0, 40.0, 20.0);
  const TopoDS_Solid box = maker.Solid();

  const TopoDS_Face topFace = faceAtZ(box, 20.0);
  const TopoDS_Face bottomFace = faceAtZ(box, 0.0);

  // Inflate ONLY the bottom face's tolerance to a coarse 0.5 mm — the kind of
  // loose face a healed or imported solid can carry — while the top (entry)
  // face stays at OCCT's tight primitive tolerance.
  const double looseTolerance = 0.5;
  BRep_Builder builder;
  builder.UpdateFace(bottomFace, looseTolerance);

  std::printf("hole entry classification\n");
  check(BRep_Tool::Tolerance(bottomFace) >= looseTolerance - 1.0e-9,
        "bottom face carries the loose tolerance (test setup)");
  check(BRep_Tool::Tolerance(topFace) < 1.0e-3, "top (entry) face stays tight (test setup)");

  const gp_Dir down(0.0, 0.0, -1.0);

  // A valid entry dead-centre on the top face, drilling down, still succeeds.
  expectAccepts(box, gp_Ax2(gp_Pnt(20.0, 20.0, 20.0), down), "valid on-surface entry is accepted");

  // The key case: an origin 0.1 mm ABOVE the top face. Under the former
  // global-max tolerance the loose 0.5 mm bottom face widened the ON band and
  // this would be wrongly accepted; scoped to the tight top entry face, it is
  // rejected.
  expectRejects(box, gp_Ax2(gp_Pnt(20.0, 20.0, 20.1), down),
                "origin above the tight entry face is rejected despite a loose face elsewhere");

  // And 0.1 mm inside the solid is still rejected (not on any boundary).
  expectRejects(box, gp_Ax2(gp_Pnt(20.0, 20.0, 19.9), down), "origin inside the solid is rejected");

  if (g_failures == 0) {
    std::printf("hole entry classification: all checks passed\n");
    return 0;
  }
  std::printf("hole entry classification: %d check(s) failed\n", g_failures);
  return 1;
}
