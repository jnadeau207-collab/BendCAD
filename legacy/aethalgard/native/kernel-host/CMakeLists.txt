cmake_minimum_required(VERSION 3.28)
project(aeth_kernel_host VERSION 0.1.0 LANGUAGES CXX)

include(FetchContent)

set(OCCT_ROOT "" CACHE PATH "Installed Open CASCADE root")
set(OCCT_LIBRARY_ROOT "" CACHE PATH "Materialized Open CASCADE runtime libraries")
set(AETH_OCCT_MANIFEST_SHA256 "" CACHE STRING "SHA-256 of the canonical OCCT build manifest")
if(NOT OCCT_ROOT)
  message(FATAL_ERROR "OCCT_ROOT must point to the pinned OCCT installation")
endif()
if(NOT OCCT_LIBRARY_ROOT)
  message(FATAL_ERROR "OCCT_LIBRARY_ROOT must point to materialized OCCT libraries")
endif()
string(LENGTH "${AETH_OCCT_MANIFEST_SHA256}" AETH_OCCT_MANIFEST_SHA256_LENGTH)
if(NOT AETH_OCCT_MANIFEST_SHA256_LENGTH EQUAL 64 OR
   NOT AETH_OCCT_MANIFEST_SHA256 MATCHES "^[0-9a-f]+$")
  message(FATAL_ERROR "AETH_OCCT_MANIFEST_SHA256 must be a lowercase SHA-256")
endif()

FetchContent_Declare(
  nlohmann_json
  GIT_REPOSITORY https://github.com/nlohmann/json.git
  GIT_TAG 65ee68451d8eb2b5f3a30b410476ab83deb3289b
  GIT_SHALLOW TRUE
)
set(JSON_BuildTests OFF CACHE INTERNAL "")
FetchContent_MakeAvailable(nlohmann_json)

set(OCCT_TOOLKITS_MANIFEST "${CMAKE_CURRENT_SOURCE_DIR}/occt-toolkits.json")
file(READ "${OCCT_TOOLKITS_MANIFEST}" OCCT_TOOLKITS_JSON)
string(JSON OCCT_TOOLKIT_COUNT LENGTH "${OCCT_TOOLKITS_JSON}" toolkits)
math(EXPR OCCT_TOOLKIT_LAST "${OCCT_TOOLKIT_COUNT} - 1")
set(OCCT_TOOLKITS "")
foreach(i RANGE ${OCCT_TOOLKIT_LAST})
  string(JSON toolkit GET "${OCCT_TOOLKITS_JSON}" toolkits ${i})
  list(APPEND OCCT_TOOLKITS "${toolkit}")
endforeach()
foreach(toolkit IN LISTS OCCT_TOOLKITS)
  find_library(${toolkit}_LIBRARY NAMES ${toolkit} PATHS "${OCCT_LIBRARY_ROOT}" NO_DEFAULT_PATH REQUIRED)
  list(APPEND OCCT_LIBRARIES "${${toolkit}_LIBRARY}")
endforeach()

configure_file(src/build_manifest.hpp.in generated/build_manifest.hpp @ONLY)

set(AETH_KERNEL_GEOMETRY_SOURCES
  src/geometry.cpp
  src/datum_feature.cpp
  src/shell_feature.cpp
  src/sheet_metal_feature.cpp
  src/surfacing_feature.cpp
  src/electrical_routing_feature.cpp
  src/mold_tooling_feature.cpp
  src/hole_entry.cpp
  src/cancel.cpp
  src/element_names.cpp
  src/naming_registry.cpp
  src/selector_print.cpp
  src/operation_hash.cpp
  src/topology.cpp
  src/geometry_measures.cpp
  src/selector_evaluator.cpp
  src/ref_resolution.cpp
)

add_executable(aeth-kernel-host
  src/main.cpp
  src/selector_print.cpp
  src/cancel.cpp
  src/operation_timeout.cpp
  src/protocol.cpp
  src/geometry.cpp
  src/datum_feature.cpp
  src/shell_feature.cpp
  src/sheet_metal_feature.cpp
  src/surfacing_feature.cpp
  src/electrical_routing_feature.cpp
  src/mold_tooling_feature.cpp
  src/hole_entry.cpp
  src/element_names.cpp
  src/naming_registry.cpp
  src/mutation.cpp
  src/ocaf_naming.cpp
  src/operation_hash.cpp
  src/topology.cpp
  src/geometry_measures.cpp
  src/selector_evaluator.cpp
  src/ref_resolution.cpp
  src/mate_frame.cpp
  src/tessellate.cpp
  src/sketch_solver.cpp
  src/hlr_projection.cpp
  src/simulation.cpp
  src/server.cpp
)
target_compile_features(aeth-kernel-host PRIVATE cxx_std_20)
target_include_directories(aeth-kernel-host PRIVATE
  "${CMAKE_CURRENT_BINARY_DIR}/generated"
  "${CMAKE_CURRENT_SOURCE_DIR}/src"
)
target_include_directories(aeth-kernel-host SYSTEM PRIVATE
  "${OCCT_ROOT}/include/opencascade"
)
target_link_libraries(aeth-kernel-host PRIVATE nlohmann_json::nlohmann_json ${OCCT_LIBRARIES})
if(MSVC)
  target_compile_definitions(aeth-kernel-host PRIVATE
    _CRT_SECURE_NO_WARNINGS
    NOMINMAX
    WIN32_LEAN_AND_MEAN
  )
  target_compile_options(aeth-kernel-host PRIVATE
    /W4 /WX /fp:precise /permissive- /Zc:__cplusplus /utf-8
  )
elseif(APPLE)
  target_compile_options(aeth-kernel-host PRIVATE -Wall -Wextra -Wpedantic -Werror -fno-fast-math)
  set_target_properties(aeth-kernel-host PROPERTIES
    BUILD_RPATH "@loader_path/../lib"
    INSTALL_RPATH "@loader_path/../lib"
  )
else()
  target_compile_options(aeth-kernel-host PRIVATE -Wall -Wextra -Wpedantic -Werror -fno-fast-math)
  set_target_properties(aeth-kernel-host PROPERTIES
    BUILD_RPATH "$ORIGIN/../lib"
    INSTALL_RPATH "$ORIGIN/../lib"
  )
endif()
install(TARGETS aeth-kernel-host RUNTIME DESTINATION bin)

enable_testing()
find_package(Threads REQUIRED)

function(aeth_configure_native_test target)
  target_compile_features(${target} PRIVATE cxx_std_20)
  target_include_directories(${target} PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/src"
    "${CMAKE_CURRENT_BINARY_DIR}/generated"
  )
  target_include_directories(${target} SYSTEM PRIVATE "${OCCT_ROOT}/include/opencascade")
  target_link_libraries(${target} PRIVATE nlohmann_json::nlohmann_json ${OCCT_LIBRARIES})
  if(MSVC)
    target_compile_definitions(${target} PRIVATE
      _CRT_SECURE_NO_WARNINGS
      NOMINMAX
      WIN32_LEAN_AND_MEAN
    )
    target_compile_options(${target} PRIVATE
      /W4 /WX /fp:precise /permissive- /Zc:__cplusplus /utf-8
    )
  elseif(APPLE)
    target_compile_options(${target} PRIVATE -Wall -Wextra -Wpedantic -Werror -fno-fast-math)
    set_target_properties(${target} PROPERTIES BUILD_RPATH "${OCCT_LIBRARY_ROOT}")
  else()
    target_compile_options(${target} PRIVATE -Wall -Wextra -Wpedantic -Werror -fno-fast-math)
    set_target_properties(${target} PROPERTIES BUILD_RPATH "${OCCT_LIBRARY_ROOT}")
  endif()
endfunction()

add_executable(aeth-bounded-feasibility-test test/bounded_feasibility_test.cpp)
target_compile_features(aeth-bounded-feasibility-test PRIVATE cxx_std_20)
target_include_directories(aeth-bounded-feasibility-test PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/src")
if(MSVC)
  target_compile_options(aeth-bounded-feasibility-test PRIVATE
    /W4 /WX /fp:precise /permissive- /Zc:__cplusplus /utf-8
  )
else()
  target_compile_options(aeth-bounded-feasibility-test PRIVATE
    -Wall -Wextra -Wpedantic -Werror -fno-fast-math
  )
endif()
add_test(NAME bounded-feasibility COMMAND aeth-bounded-feasibility-test)

add_executable(aeth-tessellate-lod-test
  src/cancel.cpp
  src/tessellate.cpp
  test/tessellate_lod_test.cpp
)
aeth_configure_native_test(aeth-tessellate-lod-test)
add_test(NAME tessellate-lod COMMAND aeth-tessellate-lod-test)

add_executable(aeth-hole-entry-test
  src/hole_entry.cpp
  test/hole_entry_test.cpp
)
aeth_configure_native_test(aeth-hole-entry-test)
add_test(NAME hole-entry COMMAND aeth-hole-entry-test)

add_executable(aeth-step-export-test
  ${AETH_KERNEL_GEOMETRY_SOURCES}
  test/step_export_test.cpp
)
aeth_configure_native_test(aeth-step-export-test)
add_test(NAME step-export COMMAND aeth-step-export-test)

add_executable(aeth-step-import-test
  ${AETH_KERNEL_GEOMETRY_SOURCES}
  test/step_import_test.cpp
)
aeth_configure_native_test(aeth-step-import-test)
add_test(NAME step-import COMMAND aeth-step-import-test)

add_executable(aeth-mesh-import-test
  ${AETH_KERNEL_GEOMETRY_SOURCES}
  test/mesh_import_test.cpp
)
aeth_configure_native_test(aeth-mesh-import-test)
add_test(NAME mesh-import COMMAND aeth-mesh-import-test)

add_executable(aeth-naming-registry-test
  ${AETH_KERNEL_GEOMETRY_SOURCES}
  test/naming_registry_test.cpp
)
aeth_configure_native_test(aeth-naming-registry-test)
add_test(NAME naming-registry COMMAND aeth-naming-registry-test)

add_executable(aeth-selector-evaluator-test
  ${AETH_KERNEL_GEOMETRY_SOURCES}
  test/selector_evaluator_test.cpp
)
aeth_configure_native_test(aeth-selector-evaluator-test)
add_test(NAME selector-evaluator COMMAND aeth-selector-evaluator-test)

add_executable(aeth-ref-resolution-test
  ${AETH_KERNEL_GEOMETRY_SOURCES}
  test/ref_resolution_test.cpp
)
aeth_configure_native_test(aeth-ref-resolution-test)
add_test(NAME ref-resolution COMMAND aeth-ref-resolution-test)

add_executable(aeth-topology-test
  ${AETH_KERNEL_GEOMETRY_SOURCES}
  test/topology_test.cpp
)
aeth_configure_native_test(aeth-topology-test)
add_test(NAME topology COMMAND aeth-topology-test)

add_executable(aeth-catalog-wave1-test
  ${AETH_KERNEL_GEOMETRY_SOURCES}
  test/catalog_wave1_test.cpp
)
aeth_configure_native_test(aeth-catalog-wave1-test)
add_test(NAME catalog-wave1 COMMAND aeth-catalog-wave1-test)

add_executable(aeth-sketch-region-test
  ${AETH_KERNEL_GEOMETRY_SOURCES}
  test/sketch_region_test.cpp
)
aeth_configure_native_test(aeth-sketch-region-test)
add_test(NAME sketch-region COMMAND aeth-sketch-region-test)

add_executable(aeth-sweep-associative-test
  ${AETH_KERNEL_GEOMETRY_SOURCES}
  test/sweep_associative_test.cpp
)
aeth_configure_native_test(aeth-sweep-associative-test)
add_test(NAME sweep-associative COMMAND aeth-sweep-associative-test)

add_executable(aeth-catalog-wave2-test
  ${AETH_KERNEL_GEOMETRY_SOURCES}
  test/catalog_wave2_test.cpp
)
aeth_configure_native_test(aeth-catalog-wave2-test)
add_test(NAME catalog-wave2 COMMAND aeth-catalog-wave2-test)

add_executable(aeth-mate-frame-test
  ${AETH_KERNEL_GEOMETRY_SOURCES}
  src/mate_frame.cpp
  test/mate_frame_test.cpp
)
aeth_configure_native_test(aeth-mate-frame-test)
add_test(NAME mate-frame COMMAND aeth-mate-frame-test)

add_executable(aeth-sheet-metal-test
  ${AETH_KERNEL_GEOMETRY_SOURCES}
  test/sheet_metal_test.cpp
)
aeth_configure_native_test(aeth-sheet-metal-test)
add_test(NAME sheet-metal COMMAND aeth-sheet-metal-test)

add_executable(aeth-surfacing-test
  ${AETH_KERNEL_GEOMETRY_SOURCES}
  src/tessellate.cpp
  test/surfacing_test.cpp
)
aeth_configure_native_test(aeth-surfacing-test)
add_test(NAME surfacing COMMAND aeth-surfacing-test)

add_executable(aeth-electrical-routing-test
  ${AETH_KERNEL_GEOMETRY_SOURCES}
  test/electrical_routing_test.cpp
)
aeth_configure_native_test(aeth-electrical-routing-test)
add_test(NAME electrical-routing COMMAND aeth-electrical-routing-test)

add_executable(aeth-mold-tooling-test
  ${AETH_KERNEL_GEOMETRY_SOURCES}
  src/tessellate.cpp
  test/mold_tooling_test.cpp
)
aeth_configure_native_test(aeth-mold-tooling-test)
add_test(NAME mold-tooling COMMAND aeth-mold-tooling-test)

add_executable(aeth-tolerance-budget-test
  ${AETH_KERNEL_GEOMETRY_SOURCES}
  test/tolerance_budget_test.cpp
)
aeth_configure_native_test(aeth-tolerance-budget-test)
add_test(NAME tolerance-budget COMMAND aeth-tolerance-budget-test)

add_executable(aeth-local-face-offset-test
  ${AETH_KERNEL_GEOMETRY_SOURCES}
  test/local_face_offset_test.cpp
)
aeth_configure_native_test(aeth-local-face-offset-test)
add_test(NAME local-face-offset COMMAND aeth-local-face-offset-test)

add_executable(aeth-body-pool-snapshot-test test/body_pool_snapshot_test.cpp)
aeth_configure_native_test(aeth-body-pool-snapshot-test)
add_test(NAME body-pool-snapshot COMMAND aeth-body-pool-snapshot-test)

add_executable(aeth-extrude-topology-test
  ${AETH_KERNEL_GEOMETRY_SOURCES}
  test/extrude_topology_test.cpp
)
aeth_configure_native_test(aeth-extrude-topology-test)
add_test(NAME extrude-topology COMMAND aeth-extrude-topology-test)

add_executable(aeth-revolve-topology-test
  ${AETH_KERNEL_GEOMETRY_SOURCES}
  test/revolve_topology_test.cpp
)
aeth_configure_native_test(aeth-revolve-topology-test)
add_test(NAME revolve-topology COMMAND aeth-revolve-topology-test)

get_filename_component(AETH_OP_HASH_GOLDEN
  "${CMAKE_CURRENT_SOURCE_DIR}/../../fixtures/golden/operation-hash-v1.json" ABSOLUTE)
add_executable(aeth-canonical-hash-test
  src/selector_print.cpp
  src/operation_hash.cpp
  test/canonical_hash_test.cpp
)
target_compile_features(aeth-canonical-hash-test PRIVATE cxx_std_20)
target_include_directories(aeth-canonical-hash-test PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/src")
target_link_libraries(aeth-canonical-hash-test PRIVATE nlohmann_json::nlohmann_json)
target_compile_definitions(aeth-canonical-hash-test PRIVATE
  "AETH_OP_HASH_GOLDEN_PATH=\"${AETH_OP_HASH_GOLDEN}\"")
if(MSVC)
  target_compile_definitions(aeth-canonical-hash-test PRIVATE
    _CRT_SECURE_NO_WARNINGS NOMINMAX WIN32_LEAN_AND_MEAN)
  target_compile_options(aeth-canonical-hash-test PRIVATE
    /W4 /WX /fp:precise /permissive- /Zc:__cplusplus /utf-8)
else()
  target_compile_options(aeth-canonical-hash-test PRIVATE
    -Wall -Wextra -Wpedantic -Werror -fno-fast-math)
endif()
add_test(NAME canonical-hash COMMAND aeth-canonical-hash-test)

get_filename_component(AETH_SELECTOR_PRINT_GOLDEN
  "${CMAKE_CURRENT_SOURCE_DIR}/../../fixtures/golden/selector-print-v1.json" ABSOLUTE)
add_executable(aeth-selector-print-test
  src/selector_print.cpp
  src/operation_hash.cpp
  test/selector_print_test.cpp
)
target_compile_features(aeth-selector-print-test PRIVATE cxx_std_20)
target_include_directories(aeth-selector-print-test PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/src")
target_link_libraries(aeth-selector-print-test PRIVATE nlohmann_json::nlohmann_json)
target_compile_definitions(aeth-selector-print-test PRIVATE
  "AETH_SELECTOR_PRINT_GOLDEN_PATH=\"${AETH_SELECTOR_PRINT_GOLDEN}\"")
if(MSVC)
  target_compile_definitions(aeth-selector-print-test PRIVATE
    _CRT_SECURE_NO_WARNINGS NOMINMAX WIN32_LEAN_AND_MEAN)
  target_compile_options(aeth-selector-print-test PRIVATE
    /W4 /WX /fp:precise /permissive- /Zc:__cplusplus /utf-8)
else()
  target_compile_options(aeth-selector-print-test PRIVATE
    -Wall -Wextra -Wpedantic -Werror -fno-fast-math)
endif()
add_test(NAME selector-print COMMAND aeth-selector-print-test)

add_executable(aeth-operation-watchdog-test
  src/operation_timeout.cpp
  test/operation_watchdog_test.cpp
)
target_compile_features(aeth-operation-watchdog-test PRIVATE cxx_std_20)
target_include_directories(aeth-operation-watchdog-test PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/src")
target_link_libraries(aeth-operation-watchdog-test PRIVATE Threads::Threads)
if(MSVC)
  target_compile_definitions(aeth-operation-watchdog-test PRIVATE
    _CRT_SECURE_NO_WARNINGS NOMINMAX WIN32_LEAN_AND_MEAN)
  target_compile_options(aeth-operation-watchdog-test PRIVATE
    /W4 /WX /fp:precise /permissive- /Zc:__cplusplus /utf-8)
else()
  target_compile_options(aeth-operation-watchdog-test PRIVATE
    -Wall -Wextra -Wpedantic -Werror -fno-fast-math)
endif()
add_test(NAME operation-watchdog COMMAND aeth-operation-watchdog-test)

add_executable(aeth-replay-cache-test
  ${AETH_KERNEL_GEOMETRY_SOURCES}
  src/tessellate.cpp
  test/replay_cache_test.cpp
)
aeth_configure_native_test(aeth-replay-cache-test)
add_test(NAME replay-cache COMMAND aeth-replay-cache-test)

FetchContent_Declare(
  eigen
  GIT_REPOSITORY https://gitlab.com/libeigen/eigen.git
  GIT_TAG 3147391d946bb4b6c68edd901f2add6ac1f31f8c
  GIT_SHALLOW TRUE
  SYSTEM
  EXCLUDE_FROM_ALL
)
set(BUILD_TESTING OFF CACHE INTERNAL "")
set(EIGEN_BUILD_DOC OFF CACHE INTERNAL "")
set(EIGEN_BUILD_TESTING OFF CACHE INTERNAL "")
set(EIGEN_BUILD_PKGCONFIG OFF CACHE INTERNAL "")
# The pinned Eigen release always adds its optional LAPACK subdirectory. That
# subdirectory calls check_language(Fortran), even though this host consumes
# Eigen as a header-only C++ dependency and has no Fortran target. Mark the
# unused language unavailable before Eigen is added so CMake does not discover
# a PATH-provided MinGW compiler and try to link it into the MSVC build. FORCE
# also clears a stale compiler path when a build directory is reused.
set(CMAKE_Fortran_COMPILER "NOTFOUND" CACHE FILEPATH
  "Fortran is intentionally disabled for the C++-only kernel host" FORCE)
FetchContent_MakeAvailable(eigen)

set(PLANEGCS_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/third_party/planegcs")
add_library(aeth-planegcs STATIC
  "${PLANEGCS_ROOT}/upstream/App/planegcs/GCS.cpp"
  "${PLANEGCS_ROOT}/upstream/App/planegcs/Constraints.cpp"
  "${PLANEGCS_ROOT}/upstream/App/planegcs/Geo.cpp"
  "${PLANEGCS_ROOT}/upstream/App/planegcs/SubSystem.cpp"
  "${PLANEGCS_ROOT}/upstream/App/planegcs/qp_eq.cpp"
)
target_compile_features(aeth-planegcs PRIVATE cxx_std_20)
target_include_directories(aeth-planegcs PUBLIC
  "${PLANEGCS_ROOT}/upstream/App/planegcs"
  "${PLANEGCS_ROOT}/shim"
)
target_link_libraries(aeth-planegcs PUBLIC Eigen3::Eigen)
target_compile_definitions(aeth-planegcs PUBLIC EIGEN_MPL2_ONLY)
if(MSVC)
  target_compile_definitions(aeth-planegcs PRIVATE
    _CRT_SECURE_NO_WARNINGS NOMINMAX WIN32_LEAN_AND_MEAN)
  target_compile_options(aeth-planegcs PRIVATE
    /W4 /WX /fp:precise /permissive- /Zc:__cplusplus /utf-8 /external:W0
    /wd4267 /wd4456 /wd4458)
else()
  target_compile_options(aeth-planegcs PRIVATE
    -Wall -Wextra -Werror -fno-fast-math -Wno-shadow -Wno-conversion)
endif()

add_executable(aeth-sketch-solver-test
  src/sketch_solver.cpp
  test/sketch_solver_test.cpp
)
target_compile_features(aeth-sketch-solver-test PRIVATE cxx_std_20)
target_include_directories(aeth-sketch-solver-test PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/src")
target_link_libraries(aeth-sketch-solver-test PRIVATE aeth-planegcs)
if(MSVC)
  target_compile_definitions(aeth-sketch-solver-test PRIVATE
    _CRT_SECURE_NO_WARNINGS NOMINMAX WIN32_LEAN_AND_MEAN)
  target_compile_options(aeth-sketch-solver-test PRIVATE
    /W4 /WX /fp:precise /permissive- /Zc:__cplusplus /utf-8 /external:W0)
else()
  target_compile_options(aeth-sketch-solver-test PRIVATE
    -Wall -Wextra -Wpedantic -Werror -fno-fast-math)
endif()
add_test(NAME sketch-solver COMMAND aeth-sketch-solver-test)

add_executable(aeth-hlr-projection-test
  src/hlr_projection.cpp
  test/hlr_projection_test.cpp
)
target_compile_features(aeth-hlr-projection-test PRIVATE cxx_std_20)
target_include_directories(aeth-hlr-projection-test PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/src")
target_include_directories(aeth-hlr-projection-test SYSTEM PRIVATE
  "${OCCT_ROOT}/include/opencascade"
)
target_link_libraries(aeth-hlr-projection-test PRIVATE ${OCCT_LIBRARIES})
if(MSVC)
  target_compile_definitions(aeth-hlr-projection-test PRIVATE
    _CRT_SECURE_NO_WARNINGS NOMINMAX WIN32_LEAN_AND_MEAN)
  target_compile_options(aeth-hlr-projection-test PRIVATE
    /W4 /WX /fp:precise /permissive- /Zc:__cplusplus /utf-8 /external:W0)
else()
  target_compile_options(aeth-hlr-projection-test PRIVATE
    -Wall -Wextra -Wpedantic -Werror -fno-fast-math)
endif()
add_test(NAME hlr-projection COMMAND aeth-hlr-projection-test)

# The simulation test drives the REAL evaluation path — EvaluateOperations
# with a registry, then boundary conditions through the selector evaluator —
# so it links the full geometry source set like the selector-evaluator test.
add_executable(aeth-simulation-test
  ${AETH_KERNEL_GEOMETRY_SOURCES}
  src/simulation.cpp
  test/simulation_test.cpp
)
aeth_configure_native_test(aeth-simulation-test)
add_test(NAME simulation COMMAND aeth-simulation-test)

target_link_libraries(aeth-kernel-host PRIVATE aeth-planegcs)

if(WIN32)
  file(GLOB OCCT_RUNTIME_LIBRARIES "${OCCT_LIBRARY_ROOT}/../bin/*.dll")
  install(FILES ${OCCT_RUNTIME_LIBRARIES} DESTINATION bin)
elseif(APPLE)
  file(GLOB OCCT_RUNTIME_LIBRARIES "${OCCT_LIBRARY_ROOT}/*.dylib")
  install(FILES ${OCCT_RUNTIME_LIBRARIES} DESTINATION lib)
else()
  file(GLOB OCCT_RUNTIME_LIBRARIES "${OCCT_LIBRARY_ROOT}/*.so.[0-9]*")
  install(FILES ${OCCT_RUNTIME_LIBRARIES} DESTINATION lib)
endif()
install(
  DIRECTORY "${OCCT_ROOT}/share/opencascade/resources/"
  DESTINATION share/opencascade/resources
)
