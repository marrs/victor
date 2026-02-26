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
    (is (= (xml.str [:p {} "hello" [:em {} "world"]]) "<p>hello<em>world</em></p>")))

  (testing "text element with content"
    (is (= (xml.str [:text {} "Hello"]) "<text>Hello</text>")))

  (testing "text element with font attributes"
    (is (= (xml.str [:text {:x "10" :y "20" :font-family "Helvetica" :font-size "12"} "Hello"])
           "<text font-family=\"Helvetica\" font-size=\"12\" x=\"10\" y=\"20\">Hello</text>")))

  (testing "text content escapes ampersand"
    (is (= (xml.str [:text {} "a & b"]) "<text>a &amp; b</text>")))

  (testing "text content escapes less-than"
    (is (= (xml.str [:text {} "a < b"]) "<text>a &lt; b</text>")))

  (testing "text content escapes greater-than"
    (is (= (xml.str [:text {} "a > b"]) "<text>a &gt; b</text>")))

  (testing "attr value escapes ampersand"
    (is (= (xml.str [:circle {:fill "a&b"}]) "<circle fill=\"a&amp;b\"/>")))

  (testing "attr value escapes double-quote"
    (is (= (xml.str [:circle {:fill "a\"b"}]) "<circle fill=\"a&quot;b\"/>"))))

(run-tests)
