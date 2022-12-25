#include <catch2/catch.hpp>
#include <cstdint>

std::uint64_t Fibonacci(std::uint64_t number) {
  return number < 2 ? 1 : Fibonacci(number - 1) + Fibonacci(number - 2);
}

TEST_CASE("simple test case that passes", "[simpleTestCasePasses]") {
  REQUIRE(1 == 1);
}

TEST_CASE("simple test case that fails", "[simpleTestCaseFails]") {
  REQUIRE(1 == 0);
}

TEST_CASE("test case with: / \" , [] that passes", "[specialCharTestPasses]") {
  REQUIRE(1 != 0);
}

TEST_CASE("test case with: / \" , [] that fails", "[specialCharTestFails]") {
  REQUIRE(1 != 1);
}

TEST_CASE("test case with multiple checks passes",
          "[multipleChecksTestPasses]") {
  CHECK(Fibonacci(2) != 0);
  REQUIRE(1 == 1);
}

TEST_CASE("test case with multiple checks fails", "[multipleChecksTestFails]") {
  CHECK(Fibonacci(2) == 1);
  REQUIRE(1 == 0);
}

TEST_CASE("test case with a section", "[testCaseWithSections]") {
  SECTION("section that passes") {
    CHECK(1 == 1);
    REQUIRE(1 != 0);
  }
}

TEST_CASE("test case with sections", "[testCaseWithSections]") {
  SECTION("section that passes") {
    CHECK(1 == 1);
    REQUIRE(1 != 0);
  }
  SECTION("section that fails") {
    CHECK(1 != 1);
    REQUIRE(1 == 0);
  }
}

// SCENARIO("vector can be sized and resized", "[scenarioTest]") {
//   GIVEN("An empty vector") {
//     auto v = std::vector<std::string>{};
//
//     // Validate assumption of the GIVEN clause
//     THEN("The size and capacity start at 0") {
//       REQUIRE(v.size() == 0);
//       REQUIRE(v.capacity() == 0);
//     }
//
//     // Validate one use case for the GIVEN object
//     WHEN("push_back() is called") {
//       v.push_back("hullo");
//
//       THEN("The size changes") {
//         REQUIRE(v.size() == 1);
//         REQUIRE(v.capacity() >= 1);
//       }
//     }
//   }
// }
//
// TEMPLATE_TEST_CASE("vectors can be sized and resized", "[templateTest]", int,
//                    std::string, (std::tuple<int, float>)) {
//
//   std::vector<TestType> v(5);
//
//   REQUIRE(v.size() == 5);
//   REQUIRE(v.capacity() >= 5);
//
//   SECTION("resizing bigger changes size and capacity") {
//     v.resize(10);
//
//     REQUIRE(v.size() == 10);
//     REQUIRE(v.capacity() >= 10);
//   }
//   SECTION("resizing smaller changes size but not capacity") {
//     v.resize(0);
//
//     REQUIRE(v.size() == 0);
//     REQUIRE(v.capacity() >= 5);
//
//     SECTION("We can use the 'swap trick' to reset the capacity") {
//       std::vector<TestType> empty;
//       empty.swap(v);
//
//       REQUIRE(v.capacity() == 0);
//     }
//   }
//   SECTION("reserving smaller does not change size or capacity") {
//     v.reserve(0);
//
//     REQUIRE(v.size() == 5);
//     REQUIRE(v.capacity() >= 5);
//   }
// }
