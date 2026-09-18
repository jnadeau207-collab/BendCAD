#pragma once

#include <stdexcept>

#include <BRepBuilderAPI_MakeShape.hxx>
#include <NCollection_IndexedMap.hxx>
#include <NCollection_List.hxx>
#include <TopAbs_ShapeEnum.hxx>
#include <TopExp.hxx>
#include <TopTools_ShapeMapHasher.hxx>
#include <TopoDS_Shape.hxx>

namespace aeth {

/// Adapts a BRepFilletAPI local operation (MakeFillet, MakeChamfer) to
/// BRepTools_History's template constructor, which consumes the standard
/// IsDeleted()/Modified()/Generated() algorithm surface.
///
/// Modified() and Generated() are forwarded untouched: Modified() reports the
/// re-trimmed images kept by the internal TopOpeBRepBuild split maps, and
/// Generated() reports the new blend faces recorded for the spine edges (and
/// corner vertices, when a corner patch exists) in the ChFi3d builder's
/// edge/vertex-image map.
///
/// IsDeleted() is NOT forwarded for edges and vertices, because the pinned
/// implementation is only truthful for faces: it answers
/// `!(myMap.Contains(S) || IsSplit(S, ...))` where `myMap` is populated with
/// the result FACES only. BRepFilletAPI_MakeFillet::Build and
/// BRepFilletAPI_MakeChamfer::Build populate that map identically in the
/// pinned source, so the correction covers both local operations. Every
/// identity-surviving edge and vertex would otherwise read "deleted", and
/// feeding that to BRepTools_History would record preserved topology as
/// removed — a corrupted history that classifies survivors as "gone". For
/// non-faces this adapter instead applies BRepTools_History's own removal
/// definition (R(S) == 1 means S is not an output shape and M(S) is empty):
/// removal is exact TShape non-membership in the result plus an empty
/// Modified() list — set membership, never geometric similarity. For faces
/// the algorithm's answer is used and cross-checked against result
/// membership; an incoherent answer fails the request instead of being
/// papered over.
class LocalOperationHistorySource final {
public:
  LocalOperationHistorySource(BRepBuilderAPI_MakeShape& maker, const TopoDS_Shape& result)
      : maker_(maker) {
    TopExp::MapShapes(result, resultSubshapes_);
  }

  bool IsDeleted(const TopoDS_Shape& shape) {
    if (shape.ShapeType() == TopAbs_FACE) {
      const bool deleted = maker_.IsDeleted(shape);
      if (deleted && resultSubshapes_.Contains(shape)) {
        throw std::runtime_error(
            "local-operation history reports a deleted face that is still present in the result");
      }
      return deleted;
    }
    return !resultSubshapes_.Contains(shape) && maker_.Modified(shape).IsEmpty();
  }

  const NCollection_List<TopoDS_Shape>& Modified(const TopoDS_Shape& shape) {
    return maker_.Modified(shape);
  }

  const NCollection_List<TopoDS_Shape>& Generated(const TopoDS_Shape& shape) {
    return maker_.Generated(shape);
  }

private:
  BRepBuilderAPI_MakeShape& maker_;
  NCollection_IndexedMap<TopoDS_Shape, TopTools_ShapeMapHasher> resultSubshapes_;
};

} // namespace aeth
