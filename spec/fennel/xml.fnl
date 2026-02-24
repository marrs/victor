(import-macros {: deftest : is : run-tests : testing} :src.fennel.test)
(local xml (require :src.fennel.xml))

(deftest xml.str
  (testing "self-closing-no-attr-map"
    (is (= (xml.str [:circle]) "<circle/>")))

  (testing "self-closing-empty-attr-map"
    (is (= (xml.str [:circle {}]) "<circle/>")))

  (testing "self-closing-keyword-attr-value"
    (is (= (xml.str [:circle {:fill :red}]) "<circle fill=\"red\"/>")))

  (testing "self-closing-string-attr-value"
    (is (= (xml.str [:circle {:r "40"}]) "<circle r=\"40\"/>")))

  (testing "string-child"
    (is (= (xml.str [:text {} "hello"]) "<text>hello</text>")))

  (testing "element-child-recursive"
    (is (= (xml.str [:svg {} [:circle {:r "40"}]]) "<svg><circle r=\"40\"/></svg>")))

  (testing "deep-nesting"
    (is (= (xml.str [:g {} [:g {} [:circle {}]]]) "<g><g><circle/></g></g>")))

  (testing "attrs-sorted-alphabetically"
    (is (= (xml.str [:circle {:r "40" :cx "50"}]) "<circle cx=\"50\" r=\"40\"/>")))

  (testing "namespaced-tag"
    (is (= (xml.str [:svg/rect]) "<svg:rect/>")))

  (testing "namespaced-attr-name"
    (is (= (xml.str [:circle {:xlink/href "u"}]) "<circle xlink:href=\"u\"/>")))

  (testing "multiple-element-children"
    (is (= (xml.str [:svg {} [:circle {}] [:rect {}]]) "<svg><circle/><rect/></svg>")))

  (testing "multiple-mixed-children"
    (is (= (xml.str [:p {} "hello" [:em {} "world"]]) "<p>hello<em>world</em></p>"))))

(run-tests)
