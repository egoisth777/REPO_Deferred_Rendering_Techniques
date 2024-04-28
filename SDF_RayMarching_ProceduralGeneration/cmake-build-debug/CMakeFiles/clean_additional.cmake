# Additional clean files
cmake_minimum_required(VERSION 3.16)

if("${CONFIG}" STREQUAL "" OR "${CONFIG}" STREQUAL "Debug")
  file(REMOVE_RECURSE
  "CMakeFiles\\SDF_RayMarching_ProceduralGeneration_autogen.dir\\AutogenUsed.txt"
  "CMakeFiles\\SDF_RayMarching_ProceduralGeneration_autogen.dir\\ParseCache.txt"
  "SDF_RayMarching_ProceduralGeneration_autogen"
  )
endif()
