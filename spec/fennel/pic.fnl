(import-macros {: deftest : is : run-tests : testing : are} :src.fennel.test)
(local pic (require :src.fennel.pic))

(deftest pic.eps-y
  (are [y result] (= result (pic.eps-y 101 y))
    0   101   ;; SVG origin maps to top of EPS page
    101 0     ;; SVG bottom maps to EPS origin
    50  51    ;; near-halfway: odd height exposes rounding errors
    30  71))  ;; arbitrary value

(deftest render
  (testing "rect → SVG")

  (testing "rect with rx → SVG passthrough")

  (testing "circle → SVG")

  (testing "rect → EPS with y-flip")

  (testing "rect with rx → EPS path decomposition")

  (testing "circle → EPS with y-flip")

  (testing "document wrapper → SVG")

  (testing "document wrapper → EPS"))

(run-tests)
