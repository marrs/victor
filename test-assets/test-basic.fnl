(import-macros {: deftest : is : testing : are : thrown? : run-tests} :src.fennel.test)

(deftest arithmetic
  (testing "addition"
    (is (= (+ 1 1) 2))
    (is (= (+ 0 0) 0)))
  (testing "subtraction"
    (is (= (- 5 3) 2))))

(deftest strings
  (is (= (.. "hello" ", " "world") "hello, world"))
  (is (= (string.len "abc") 3)))

(deftest tabular
  (are [xx yy] (= xx yy)
    1        1
    "hello"  "hello"
    true     true))

(deftest errors
  (is (thrown? (error "boom")))
  (is (not (thrown? (+ 1 1)))))

(run-tests)
