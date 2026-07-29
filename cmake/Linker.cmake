macro(sysarchPalyground_configure_linker project_name)
  set(sysarchPalyground_USER_LINKER_OPTION
    "DEFAULT"
      CACHE STRING "Linker to be used")
    set(sysarchPalyground_USER_LINKER_OPTION_VALUES "DEFAULT" "SYSTEM" "LLD" "GOLD" "BFD" "MOLD" "SOLD" "APPLE_CLASSIC" "MSVC")
  set_property(CACHE sysarchPalyground_USER_LINKER_OPTION PROPERTY STRINGS ${sysarchPalyground_USER_LINKER_OPTION_VALUES})
  list(
    FIND
    sysarchPalyground_USER_LINKER_OPTION_VALUES
    ${sysarchPalyground_USER_LINKER_OPTION}
    sysarchPalyground_USER_LINKER_OPTION_INDEX)

  if(${sysarchPalyground_USER_LINKER_OPTION_INDEX} EQUAL -1)
    message(
      STATUS
        "Using custom linker: '${sysarchPalyground_USER_LINKER_OPTION}', explicitly supported entries are ${sysarchPalyground_USER_LINKER_OPTION_VALUES}")
  endif()

  set_target_properties(${project_name} PROPERTIES LINKER_TYPE "${sysarchPalyground_USER_LINKER_OPTION}")
endmacro()
