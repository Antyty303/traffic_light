cmake_minimum_required(VERSION 3.20)
project(Vtb_traffic_light LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
add_subdirectory(3rdparty/gtest)

find_package(verilator REQUIRED)

file(GLOB SV_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/*.sv")

add_executable(Vtb_traffic_light tb/Vtb_traffic_light.cpp)
verilate(Vtb_traffic_light
    SOURCES ${SV_SOURCES}
    TOP_MODULE traffic_light_top
    PREFIX Vtraffic_light_top
    TRACE
    VERILATOR_ARGS 
	--public-flat-rw
	-GDIV_LIMIT_1S=20
)

target_link_libraries(Vtb_traffic_light PRIVATE gtest gtest_main)