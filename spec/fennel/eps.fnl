(import-macros {: deftest : is : run-tests : testing : thrown?} :src.fennel.test)
(local eps (require :src.fennel.eps))

(deftest eps.str
  (testing "zero-arg operator"
    (is (= (eps.str [:stroke]) "stroke")))

  (testing "single-arg operator"
    (is (= (eps.str [:setlinewidth {:w 2}]) "2 setlinewidth")))

  (testing "multi-arg operator"
    (is (= (eps.str [:moveto {:x 10 :y 20}]) "10 20 moveto")))

  (testing "args ordered correctly regardless of hashmap insertion order"
    (is (= (eps.str [:setrgbcolor {:b 0 :r 1 :g 0.5}]) "1 0.5 0 setrgbcolor")))

  (testing "document wrapper generates EPS header and footer"
    (is (= (eps.str [:eps {:width 100 :height 100}])
           "%!PS-Adobe-3.0 EPSF-3.0\n%%BoundingBox: 0 0 100 100\n%%EndComments\n%%EOF")))

  (testing "document wrapper with multiple operators"
    (is (= (eps.str [:eps {:width 100 :height 100} [:stroke]])
           "%!PS-Adobe-3.0 EPSF-3.0\n%%BoundingBox: 0 0 100 100\n%%EndComments\nstroke\n%%EOF")))

  (testing "error on unknown operator"
    (is (thrown? (eps.str [:foobar]))))

  (testing "error on missing required argument"
    (is (thrown? (eps.str [:moveto {:x 10}]))))

  (testing "warning on extra keys in hashmap"
    (is (= (eps.str [:moveto {:x 10 :y 20 :z 99}]) "10 20 moveto"))))

(run-tests)
