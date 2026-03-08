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
    (is (= (eps.str [:moveto {:x 10 :y 20 :z 99}]) "10 20 moveto")))

  (testing "setfont emits findfont/scalefont/setfont sequence"
    (is (= (eps.str [:setfont {:name "Helvetica" :size 14}])
           "/Helvetica findfont 14 scalefont setfont")))

  (testing "show emits plain PS string literal"
    (is (= (eps.str [:show {:str "Hi"}])
           "(Hi) show")))

  (testing "show escapes PS special characters (parens, backslash)"
    (is (= (eps.str [:show {:str "(ok\\)"}])
           "(\\050ok\\134\\051) show")))

  (testing "glyphshow emits named glyph operator"
    (is (= (eps.str [:glyphshow {:name "u1F642"}])
           "/u1F642 glyphshow")))

  (testing "language spec"
    (testing "zero-arg operators"
      (is (= (eps.str [:fill])        "fill")        "fill")
      (is (= (eps.str [:eofill])      "eofill")      "eofill")
      (is (= (eps.str [:newpath])     "newpath")     "newpath")
      (is (= (eps.str [:closepath])   "closepath")   "closepath")
      (is (= (eps.str [:clip])        "clip")        "clip")
      (is (= (eps.str [:gsave])       "gsave")       "gsave")
      (is (= (eps.str [:grestore])    "grestore")    "grestore")
      (is (= (eps.str [:showpage])    "showpage")    "showpage")
      (is (= (eps.str [:flattenpath]) "flattenpath") "flattenpath")
      (is (= (eps.str [:strokepath])  "strokepath")  "strokepath"))

    (testing "path construction"
      (is (= (eps.str [:lineto {:x 30 :y 40}]) "30 40 lineto")
          "lineto emits x y lineto")
      (is (= (eps.str [:rmoveto {:dx 5 :dy -10}]) "5 -10 rmoveto")
          "rmoveto emits dx dy rmoveto")
      (is (= (eps.str [:rlineto {:dx 10 :dy 0}]) "10 0 rlineto")
          "rlineto emits dx dy rlineto")
      (is (= (eps.str [:curveto {:x1 10 :y1 20 :x2 30 :y2 40 :x3 50 :y3 60}])
             "10 20 30 40 50 60 curveto")
          "curveto emits x1 y1 x2 y2 x3 y3 curveto")
      (is (= (eps.str [:rcurveto {:dx1 1 :dy1 -2 :dx2 3 :dy2 -4 :dx3 5 :dy3 0}])
             "1 -2 3 -4 5 0 rcurveto")
          "rcurveto emits dx1 dy1 dx2 dy2 dx3 dy3 rcurveto")
      (is (= (eps.str [:arc {:cx 50 :cy 50 :r 40 :a1 0 :a2 180}])
             "50 50 40 0 180 arc")
          "arc emits cx cy r a1 a2 arc")
      (is (= (eps.str [:arcn {:cx 50 :cy 50 :r 40 :a1 180 :a2 0}])
             "50 50 40 180 0 arcn")
          "arcn emits cx cy r a1 a2 arcn"))

    (testing "graphics state"
      (is (= (eps.str [:setgray {:v 0.5}]) "0.5 setgray")
          "setgray emits v setgray")
      (is (= (eps.str [:setlinecap {:cap 1}]) "1 setlinecap")
          "setlinecap emits cap setlinecap")
      (is (= (eps.str [:setlinejoin {:join 2}]) "2 setlinejoin")
          "setlinejoin emits join setlinejoin")
      (is (= (eps.str [:setmiterlimit {:limit 10}]) "10 setmiterlimit")
          "setmiterlimit emits limit setmiterlimit")
      (is (= (eps.str [:setdash {:array "[5 3]" :offset 0}]) "[5 3] 0 setdash")
          "setdash emits array offset setdash"))

    (testing "transforms"
      (is (= (eps.str [:translate {:tx 10 :ty 20}]) "10 20 translate")
          "translate emits tx ty translate")
      (is (= (eps.str [:rotate {:angle 45}]) "45 rotate")
          "rotate emits angle rotate")
      (is (= (eps.str [:scale {:sx 2 :sy 0.5}]) "2 0.5 scale")
          "scale emits sx sy scale"))

    (testing "rectangles"
      (is (= (eps.str [:rectfill {:x 10 :y 20 :w 100 :h 50}]) "10 20 100 50 rectfill")
          "rectfill emits x y w h rectfill")
      (is (= (eps.str [:rectstroke {:x 10 :y 20 :w 100 :h 50}]) "10 20 100 50 rectstroke")
          "rectstroke emits x y w h rectstroke"))))

(run-tests)
