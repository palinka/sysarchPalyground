include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


include(CheckCXXSourceCompiles)


macro(sysarchPalyground_supports_sanitizers)
  # Emscripten doesn't support sanitizers
  if(EMSCRIPTEN)
    set(SUPPORTS_UBSAN OFF)
    set(SUPPORTS_ASAN OFF)
  elseif((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)

    message(STATUS "Sanity checking UndefinedBehaviorSanitizer, it should be supported on this platform")
    set(TEST_PROGRAM "int main() { return 0; }")

    # Check if UndefinedBehaviorSanitizer works at link time
    set(CMAKE_REQUIRED_FLAGS "-fsanitize=undefined")
    set(CMAKE_REQUIRED_LINK_OPTIONS "-fsanitize=undefined")
    check_cxx_source_compiles("${TEST_PROGRAM}" HAS_UBSAN_LINK_SUPPORT)

    if(HAS_UBSAN_LINK_SUPPORT)
      message(STATUS "UndefinedBehaviorSanitizer is supported at both compile and link time.")
      set(SUPPORTS_UBSAN ON)
    else()
      message(WARNING "UndefinedBehaviorSanitizer is NOT supported at link time.")
      set(SUPPORTS_UBSAN OFF)
    endif()
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    if (NOT WIN32)
      message(STATUS "Sanity checking AddressSanitizer, it should be supported on this platform")
      set(TEST_PROGRAM "int main() { return 0; }")

      # Check if AddressSanitizer works at link time
      set(CMAKE_REQUIRED_FLAGS "-fsanitize=address")
      set(CMAKE_REQUIRED_LINK_OPTIONS "-fsanitize=address")
      check_cxx_source_compiles("${TEST_PROGRAM}" HAS_ASAN_LINK_SUPPORT)

      if(HAS_ASAN_LINK_SUPPORT)
        message(STATUS "AddressSanitizer is supported at both compile and link time.")
        set(SUPPORTS_ASAN ON)
      else()
        message(WARNING "AddressSanitizer is NOT supported at link time.")
        set(SUPPORTS_ASAN OFF)
      endif()
    else()
      set(SUPPORTS_ASAN ON)
    endif()
  endif()
endmacro()

macro(sysarchPalyground_setup_options)
  option(sysarchPalyground_ENABLE_HARDENING "Enable hardening" ON)
  option(sysarchPalyground_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    sysarchPalyground_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    sysarchPalyground_ENABLE_HARDENING
    OFF)

  sysarchPalyground_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR sysarchPalyground_PACKAGING_MAINTAINER_MODE)
    option(sysarchPalyground_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(sysarchPalyground_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(sysarchPalyground_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(sysarchPalyground_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(sysarchPalyground_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(sysarchPalyground_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(sysarchPalyground_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(sysarchPalyground_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(sysarchPalyground_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(sysarchPalyground_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(sysarchPalyground_ENABLE_PCH "Enable precompiled headers" OFF)
    option(sysarchPalyground_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(sysarchPalyground_ENABLE_IPO "Enable IPO/LTO" ON)
    option(sysarchPalyground_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(sysarchPalyground_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(sysarchPalyground_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(sysarchPalyground_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(sysarchPalyground_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(sysarchPalyground_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(sysarchPalyground_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(sysarchPalyground_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(sysarchPalyground_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(sysarchPalyground_ENABLE_PCH "Enable precompiled headers" OFF)
    option(sysarchPalyground_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      sysarchPalyground_ENABLE_IPO
      sysarchPalyground_WARNINGS_AS_ERRORS
      sysarchPalyground_ENABLE_SANITIZER_ADDRESS
      sysarchPalyground_ENABLE_SANITIZER_LEAK
      sysarchPalyground_ENABLE_SANITIZER_UNDEFINED
      sysarchPalyground_ENABLE_SANITIZER_THREAD
      sysarchPalyground_ENABLE_SANITIZER_MEMORY
      sysarchPalyground_ENABLE_UNITY_BUILD
      sysarchPalyground_ENABLE_CLANG_TIDY
      sysarchPalyground_ENABLE_CPPCHECK
      sysarchPalyground_ENABLE_COVERAGE
      sysarchPalyground_ENABLE_PCH
      sysarchPalyground_ENABLE_CACHE)
  endif()

  sysarchPalyground_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (sysarchPalyground_ENABLE_SANITIZER_ADDRESS OR sysarchPalyground_ENABLE_SANITIZER_THREAD OR sysarchPalyground_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(sysarchPalyground_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(sysarchPalyground_global_options)
  if(sysarchPalyground_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    sysarchPalyground_enable_ipo()
  endif()

  sysarchPalyground_supports_sanitizers()

  if(sysarchPalyground_ENABLE_HARDENING AND sysarchPalyground_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR sysarchPalyground_ENABLE_SANITIZER_UNDEFINED
       OR sysarchPalyground_ENABLE_SANITIZER_ADDRESS
       OR sysarchPalyground_ENABLE_SANITIZER_THREAD
       OR sysarchPalyground_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${sysarchPalyground_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${sysarchPalyground_ENABLE_SANITIZER_UNDEFINED}")
    sysarchPalyground_enable_hardening(sysarchPalyground_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(sysarchPalyground_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(sysarchPalyground_warnings INTERFACE)
  add_library(sysarchPalyground_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  sysarchPalyground_set_project_warnings(
    sysarchPalyground_warnings
    ${sysarchPalyground_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  include(cmake/Linker.cmake)
  # Must configure each target with linker options, we're avoiding setting it globally for now

  if(NOT EMSCRIPTEN)
    include(cmake/Sanitizers.cmake)
    sysarchPalyground_enable_sanitizers(
      sysarchPalyground_options
      ${sysarchPalyground_ENABLE_SANITIZER_ADDRESS}
      ${sysarchPalyground_ENABLE_SANITIZER_LEAK}
      ${sysarchPalyground_ENABLE_SANITIZER_UNDEFINED}
      ${sysarchPalyground_ENABLE_SANITIZER_THREAD}
      ${sysarchPalyground_ENABLE_SANITIZER_MEMORY})
  endif()

  set_target_properties(sysarchPalyground_options PROPERTIES UNITY_BUILD ${sysarchPalyground_ENABLE_UNITY_BUILD})

  if(sysarchPalyground_ENABLE_PCH)
    target_precompile_headers(
      sysarchPalyground_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(sysarchPalyground_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    sysarchPalyground_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(sysarchPalyground_ENABLE_CLANG_TIDY)
    sysarchPalyground_enable_clang_tidy(sysarchPalyground_options ${sysarchPalyground_WARNINGS_AS_ERRORS})
  endif()

  if(sysarchPalyground_ENABLE_CPPCHECK)
    sysarchPalyground_enable_cppcheck(${sysarchPalyground_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(sysarchPalyground_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    sysarchPalyground_enable_coverage(sysarchPalyground_options)
  endif()

  if(sysarchPalyground_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(sysarchPalyground_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(sysarchPalyground_ENABLE_HARDENING AND NOT sysarchPalyground_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR sysarchPalyground_ENABLE_SANITIZER_UNDEFINED
       OR sysarchPalyground_ENABLE_SANITIZER_ADDRESS
       OR sysarchPalyground_ENABLE_SANITIZER_THREAD
       OR sysarchPalyground_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    sysarchPalyground_enable_hardening(sysarchPalyground_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
