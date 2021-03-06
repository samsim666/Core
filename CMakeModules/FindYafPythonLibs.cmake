# - Find python libraries
# This module finds if Python is installed and determines where the
# include files and libraries are. It also determines what the name of
# the library is. This code sets the following variables:
#
#  PYTHONLIBS_FOUND       - have the Python libs been found
#  PYTHON_LIBRARIES       - path to the python library
#  PYTHON_INCLUDE_PATH    - path to where Python.h is found (deprecated)
#  PYTHON_INCLUDE_DIRS    - path to where Python.h is found
#  PYTHON_DEBUG_LIBRARIES - path to the debug library
#

#=============================================================================
# Copyright 2001-2009 Kitware, Inc.
#
# Distributed under the OSI-approved BSD License (the "License");
# see accompanying file Copyright.txt for details.
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#=============================================================================
# (To distributed this file outside of CMake, substitute the full
#  License text for the above reference.)

# Modifications done to the original script by Rodrigo Placencia (DarkTide) to met YafaRay's needs

INCLUDE(CMakeFindFrameworks)

# Search for the python framework on Apple.
CMAKE_FIND_FRAMEWORKS(Python)

IF(NOT REQUIRED_PYTHON_VERSION)
  SET(_CURRENT_VERSION 3.5)
ELSE(NOT REQUIRED_PYTHON_VERSION)
  SET(_CURRENT_VERSION ${REQUIRED_PYTHON_VERSION})
ENDIF(NOT REQUIRED_PYTHON_VERSION)

#UNSET(PYTHON_DEBUG_LIBRARY CACHE)
#UNSET(PYTHON_LIBRARY CACHE)
#UNSET(PYTHON_INCLUDE_DIR CACHE)

STRING(REPLACE "." "" _CURRENT_VERSION_NO_DOTS ${_CURRENT_VERSION})

IF(WIN32)
  FIND_LIBRARY(PYTHON_DEBUG_LIBRARY
    NAMES python${_CURRENT_VERSION_NO_DOTS}_d python${_CURRENT_VERSION}m_d python${_CURRENT_VERSION}mu_d python
    PATHS
    [HKEY_LOCAL_MACHINE\\SOFTWARE\\Python\\PythonCore\\${_CURRENT_VERSION}\\InstallPath]/libs/Debug
    [HKEY_LOCAL_MACHINE\\SOFTWARE\\Python\\PythonCore\\${_CURRENT_VERSION}\\InstallPath]/libs )
ENDIF(WIN32)

FIND_LIBRARY(PYTHON_LIBRARY
  NAMES python${_CURRENT_VERSION_NO_DOTS} python${_CURRENT_VERSION} python${_CURRENT_VERSION}m python${_CURRENT_VERSION}mu
  PATHS
    [HKEY_LOCAL_MACHINE\\SOFTWARE\\Python\\PythonCore\\${_CURRENT_VERSION}\\InstallPath]/libs
  PATH_SUFFIXES
    python${_CURRENT_VERSION}/config
  # Avoid finding the .dll in the PATH.  We want the .lib.
  NO_SYSTEM_ENVIRONMENT_PATH
)

SET(PYTHON_FRAMEWORK_INCLUDES)
IF(Python_FRAMEWORKS AND NOT PYTHON_INCLUDE_DIR)
  FOREACH(dir ${Python_FRAMEWORKS})
    SET(PYTHON_FRAMEWORK_INCLUDES ${PYTHON_FRAMEWORK_INCLUDES}
      ${dir}/Versions/${_CURRENT_VERSION}/include/python${_CURRENT_VERSION})
  ENDFOREACH(dir)
ENDIF(Python_FRAMEWORKS AND NOT PYTHON_INCLUDE_DIR)

FIND_PATH(PYTHON_INCLUDE_DIR
  NAMES Python.h
  PATHS
    ${PYTHON_FRAMEWORK_INCLUDES}
    [HKEY_LOCAL_MACHINE\\SOFTWARE\\Python\\PythonCore\\${_CURRENT_VERSION}\\InstallPath]/include
  PATH_SUFFIXES
    python${_CURRENT_VERSION} python${_CURRENT_VERSION}m python${_CURRENT_VERSION}mu
)

# For backward compatibility, set PYTHON_INCLUDE_PATH, but make it internal.
SET(PYTHON_INCLUDE_PATH "${PYTHON_INCLUDE_DIR}" CACHE INTERNAL 
  "Path to where Python.h is found (deprecated)")

MARK_AS_ADVANCED(
  PYTHON_DEBUG_LIBRARY
  PYTHON_LIBRARY
  PYTHON_INCLUDE_DIR
)

# Python Should be built and installed as a Framework on OSX
IF(Python_FRAMEWORKS)
  # If a framework has been selected for the include path,
  # make sure "-framework" is used to link it.
  IF("${PYTHON_INCLUDE_DIR}" MATCHES "Python\\.framework")
    SET(PYTHON_LIBRARY "")
    SET(PYTHON_DEBUG_LIBRARY "")
  ENDIF("${PYTHON_INCLUDE_DIR}" MATCHES "Python\\.framework")
  IF(NOT PYTHON_LIBRARY)
    SET (PYTHON_LIBRARY "-framework Python" CACHE FILEPATH "Python Framework" FORCE)
  ENDIF(NOT PYTHON_LIBRARY)
  IF(NOT PYTHON_DEBUG_LIBRARY)
    SET (PYTHON_DEBUG_LIBRARY "-framework Python" CACHE FILEPATH "Python Framework" FORCE)
  ENDIF(NOT PYTHON_DEBUG_LIBRARY)
ENDIF(Python_FRAMEWORKS)

# We use PYTHON_INCLUDE_DIR, PYTHON_LIBRARY and PYTHON_DEBUG_LIBRARY for the
# cache entries because they are meant to specify the location of a single
# library. We now set the variables listed by the documentation for this
# module.
if(WITH_OSX_ADDON)
# for Blender2.5 OSX we need to link to the BF_python libs build by blender ! added a switch for a choice "blender-/general use" - Jens
SET(PYTHON_INCLUDE_DIR ${YAF_USER_INCLUDE_DIRS}/Python${YAF_PY_VERSION} CACHE PATH "" FORCE)
SET(PYTHON_LIBRARIES ${YAF_USER_LIBRARY_DIRS}/BF_pythonlibs/libbf_python_ext.a ${YAF_USER_LIBRARY_DIRS}/BF_pythonlibs/libbf_python.a)
#	if (NOT YAF_OSX_PYTHON_INCLUDE_DIR)
#		SET(PYTHON_INCLUDE_DIRS ${YAF_USER_INCLUDE_DIRS}/python3.2)
#	else (NOT YAF_OSX_PYTHON_LIB)
#		SET(PYTHON_INCLUDE_DIR ${YAF_OSX_PYTHON_INCLUDE_DIR})
#	endif (NOT YAF_OSX_PYTHON_INCLUDE_DIR)
#	if (NOT YAF_OSX_PYTHON_LIB)
#		SET(PYTHON_LIBRARIES ${YAF_USER_LIBRARY_DIRS}/BF_pythonlibs/libbf_python_ext.a ${YAF_USER_LIBRARY_DIRS}/BF_pythonlibs/libbf_python.a)
#	else (NOT YAF_OSX_PYTHON_LIB)
#		SET(PYTHON_LIBRARIES ${YAF_OSX_PYTHON_LIB})
#	endif (NOT YAF_OSX_PYTHON_LIB)
else(WITH_OSX_ADDON)
SET(PYTHON_INCLUDE_DIRS "${PYTHON_INCLUDE_DIR}")
SET(PYTHON_LIBRARIES "${PYTHON_LIBRARY}")
SET(PYTHON_DEBUG_LIBRARIES "${PYTHON_DEBUG_LIBRARY}")
endif(WITH_OSX_ADDON)


INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(Python3Libs DEFAULT_MSG PYTHON_LIBRARIES PYTHON_INCLUDE_DIRS)


# PYTHON_ADD_MODULE(<name> src1 src2 ... srcN) is used to build modules for python.
# PYTHON_WRITE_MODULES_HEADER(<filename>) writes a header file you can include 
# in your sources to initialize the static python modules

GET_PROPERTY(_TARGET_SUPPORTS_SHARED_LIBS
  GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS)

FUNCTION(PYTHON_ADD_MODULE _NAME )
  OPTION(PYTHON_ENABLE_MODULE_${_NAME} "Add module ${_NAME}" TRUE)
  OPTION(PYTHON_MODULE_${_NAME}_BUILD_SHARED "Add module ${_NAME} shared" ${_TARGET_SUPPORTS_SHARED_LIBS})

  IF(PYTHON_ENABLE_MODULE_${_NAME})
    IF(PYTHON_MODULE_${_NAME}_BUILD_SHARED)
      SET(PY_MODULE_TYPE MODULE)
    ELSE(PYTHON_MODULE_${_NAME}_BUILD_SHARED)
      SET(PY_MODULE_TYPE STATIC)
      SET_PROPERTY(GLOBAL  APPEND  PROPERTY  PY_STATIC_MODULES_LIST ${_NAME})
    ENDIF(PYTHON_MODULE_${_NAME}_BUILD_SHARED)

    SET_PROPERTY(GLOBAL  APPEND  PROPERTY  PY_MODULES_LIST ${_NAME})
    ADD_LIBRARY(${_NAME} ${PY_MODULE_TYPE} ${ARGN})
#    TARGET_LINK_LIBRARIES(${_NAME} ${PYTHON_LIBRARIES})

  ENDIF(PYTHON_ENABLE_MODULE_${_NAME})
ENDFUNCTION(PYTHON_ADD_MODULE)

FUNCTION(PYTHON_WRITE_MODULES_HEADER _filename)

  GET_PROPERTY(PY_STATIC_MODULES_LIST  GLOBAL  PROPERTY PY_STATIC_MODULES_LIST)

  GET_FILENAME_COMPONENT(_name "${_filename}" NAME)
  STRING(REPLACE "." "_" _name "${_name}")
  STRING(TOUPPER ${_name} _name)

  SET(_filenameTmp "${_filename}.in")
  FILE(WRITE ${_filenameTmp} "/*Created by cmake, do not edit, changes will be lost*/\n")
  FILE(APPEND ${_filenameTmp} 
"#ifndef ${_name}
#define ${_name}

#include <Python.h>

#ifdef __cplusplus
extern \"C\" {
#endif /* __cplusplus */

")

  FOREACH(_currentModule ${PY_STATIC_MODULES_LIST})
    FILE(APPEND ${_filenameTmp} "extern void init${PYTHON_MODULE_PREFIX}${_currentModule}(void);\n\n")
  ENDFOREACH(_currentModule ${PY_STATIC_MODULES_LIST})

  FILE(APPEND ${_filenameTmp} 
"#ifdef __cplusplus
}
#endif /* __cplusplus */

")


  FOREACH(_currentModule ${PY_STATIC_MODULES_LIST})
    FILE(APPEND ${_filenameTmp} "int CMakeLoadPythonModule_${_currentModule}(void) \n{\n  static char name[]=\"${PYTHON_MODULE_PREFIX}${_currentModule}\"; return PyImport_AppendInittab(name, init${PYTHON_MODULE_PREFIX}${_currentModule});\n}\n\n")
  ENDFOREACH(_currentModule ${PY_STATIC_MODULES_LIST})

  FILE(APPEND ${_filenameTmp} "#ifndef EXCLUDE_LOAD_ALL_FUNCTION\nvoid CMakeLoadAllPythonModules(void)\n{\n")
  FOREACH(_currentModule ${PY_STATIC_MODULES_LIST})
    FILE(APPEND ${_filenameTmp} "  CMakeLoadPythonModule_${_currentModule}();\n")
  ENDFOREACH(_currentModule ${PY_STATIC_MODULES_LIST})
  FILE(APPEND ${_filenameTmp} "}\n#endif\n\n#endif\n")
  
# with CONFIGURE_FILE() cmake complains that you may not use a file created using FILE(WRITE) as input file for CONFIGURE_FILE()
  EXECUTE_PROCESS(COMMAND ${CMAKE_COMMAND} -E copy_if_different "${_filenameTmp}" "${_filename}" OUTPUT_QUIET ERROR_QUIET)

ENDFUNCTION(PYTHON_WRITE_MODULES_HEADER)
