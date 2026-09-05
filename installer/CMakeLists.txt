cmake_minimum_required(VERSION 3.16)
project(aurora-installer LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 QUIET COMPONENTS Widgets Network)
if (NOT Qt6_FOUND)
  find_package(Qt5 REQUIRED COMPONENTS Widgets Network)
  set(QT_MAJOR 5)
else()
  set(QT_MAJOR 6)
endif()

set(Qt IGNORED)
if (QT_MAJOR EQUAL 6)
  set(Qt Qt6)
else()
  set(Qt Qt5)
endif()

qt_add_executable(aurora-installer
  src/main.cpp
  src/payload.cpp
  src/engine.cpp
  src/install.cpp
  src/wizard.cpp
)

set_target_properties(aurora-installer PROPERTIES
  MACOSX_BUNDLE FALSE
  CXX_VISIBILITY_PRESET hidden
)

target_include_directories(aurora-installer PRIVATE src)
target_link_libraries(aurora-installer
  PRIVATE ${Qt}::Widgets ${Qt}::Network
)

unset(Qt)