(import-macros {: deftest : is : run-tests : testing : are} :src.fennel.test)
(local bic (require :src.fennel.bic))
(local {: nil? : deep=} (require :src.fennel.core))

(fn svg [attrs ...]
  (let [merged {:xmlns "http://www.w3.org/2000/svg" :width 200 :height 100}
        node   [:svg merged]]
    (each [k v (pairs attrs)]
      (tset merged k v))
    (each [_ child (ipairs [...])]
      (table.insert node child))
    node))

(deftest bic.eps-y
  (are [y result] (= result (bic.eps-y 101 y))
    0   101   ;; SVG origin maps to top of EPS page
    101 0     ;; SVG bottom maps to EPS origin
    50  51    ;; near-halfway: odd height exposes rounding errors
    30  71))  ;; arbitrary value

(deftest dsl
  (testing "default to EPS when no target option is specified"
           (let [[issue result]
                 (bic.dsl {} [:bic {:width 200 :height 100}
                                      [:rect {:x 10 :y 20 :width 80 :height 40}]])]
             (is (= :eps (?. result 1)))))

  (testing "default to EPS when no options are specified"
     (let [[issue result]
           (bic.dsl [:bic {:width 200 :height 100}
                             [:rect {:x 10 :y 20 :width 80 :height 40}]])]
      (is (= :eps (?. result 1)))))

  (testing "translation to SVG"
    (testing "rect"
      (let [[issue result] (bic.dsl {:target :svg}
                                     [:bic {:width 200 :height 100}
                                      [:rect {:x 10 :y 20 :width 80 :height 40}]])]
      (is (nil? issue))
      (is (deep= (svg {} [:rect {:x 10 :y 20 :width 80 :height 40}])
                 result))))

    (testing "rect with rx"
      (let [[issue result] (bic.dsl {:target :svg}
                                    [:bic {:width 200 :height 100}
                                     [:rect {:x 10 :y 20 :width 80 :height 40 :rx 8}]])]
        (is (nil? issue))
        (is (deep= (svg {} [:rect {:x 10 :y 20 :width 80 :height 40 :rx 8}])
                   result))))

    (testing "circle"
      (let [[issue result]
            (bic.dsl {:target :svg}
                     [:bic {:width 200 :height 100}
                      [:circle {:cx 50 :cy 50 :r 30}]])]
        (is (nil? issue))
        (is (deep= (svg {} [:circle {:cx 50 :cy 50 :r 30}])
                   result))))

    (testing "text"
      (let [[issue result] (bic.dsl {:target :svg}
                                    [:bic {:width 200 :height 100}
                                     [:text {:x 10 :y 20 :font "FreeSans" :size 12
                                             :str "Hello"}]])]
        (is (nil? issue))
        (is (deep= (svg {} [:text {:x 10 :y 20 :font-family "FreeSans"
                                   :font-size 12} "Hello"])
                   result)))

      (testing "Font name is set to default if :font attribute is absent"
        (tset _G :vic_font "FreeSans")
        (tset _G :vic_size 12)
        (let [[issue result] (bic.dsl {:target :svg}
                                      [:bic {:width 200 :height 100}
                                       [:text {:x 10 :y 20 :size 12 :str "Hi"}]])]
          (tset _G :vic_font nil)
          (is (nil? issue))
          (is (= "FreeSans" (?. result 3 2 :font-family))
              "Font name is set to default if :font attribute is absent")
          (is (= 12 (?. result 3 2 :font-size))
              "Font size is set to default if :size attribute is absent")))

      (testing "missing font/size with no globals fails validation"
        (let [[issue _result] (bic.dsl {:target :svg}
                                       [:bic {:width 200 :height 100}
                                        [:text {:x 10 :y 20 :str "Hi"}]])]
          (is (= :error issue.level))))

      (let [[issue result] (bic.dsl {:target :svg}
                                    [:bic {:width 200 :height 100}
                                     [:text {:x 10 :y 20 :font "FreeSans" :size 12
                                             :str "☺"}]])]
        (is (deep= (svg {} [:text {:x 10 :y 20 :font-family "FreeSans"
                                   :font-size 12} "☺"])
                   result)
            "Non-ASCII character passes through as UTF-8"))

      (let [[issue result] (bic.dsl {:target :eps}
                                    [:bic {:width 200 :height 100}
                                     [:text {:x 10 :y 20 :font "FreeSans" :size 12
                                             :str "☺"}]])]
        (is (deep= [:eps {:width 200 :height 100}
                    [:setfont {:name "FreeSans" :size 12}]
                    [:moveto {:x 10 :y (bic.eps-y 100 20)}]
                    [:glyphshow {:name "smileface"}]]
                   result)
            "Non-ASCII code point emits glyphshow with post table name")))

    (testing "path"
      (fn path-svg [cmds ?attrs]
        (let [attrs (or ?attrs {})]
          (tset attrs :d cmds)
          (bic.dsl {:target :svg} [:bic {:width 200 :height 100} [:path attrs]])))

      (testing "produces a :path node with a d attribute"
        (let [[issue result] (path-svg [[:move-abs {:x 10 :y 20}] [:close {}]])]
          (is (nil? issue))
          (is (= :path (?. result 3 1)))
          (is (= "M 10 20 Z" (?. result 3 2 :d)))))

      (testing "[:move-abs] emits absolute M command"
        (let [[issue result] (path-svg [[:move-abs {:x 10 :y 20}]])]
          (is (nil? issue))
          (is (= "M 10 20" (?. result 3 2 :d)))))

      (testing "[:move-rel] emits relative m command"
        (let [[issue result] (path-svg [[:move-abs {:x 0 :y 0}] [:move-rel {:dx 5 :dy 10}]])]
          (is (nil? issue))
          (is (= "M 0 0 m 5 10" (?. result 3 2 :d)))))

      (testing "[:line-abs] emits absolute L command"
        (let [[issue result] (path-svg [[:move-abs {:x 0 :y 0}] [:line-abs {:x 50 :y 30}]])]
          (is (nil? issue))
          (is (= "M 0 0 L 50 30" (?. result 3 2 :d)))))

      (testing "[:line-rel] emits relative l command"
        (let [[issue result] (path-svg [[:move-abs {:x 0 :y 0}] [:line-rel {:dx 10 :dy 5}]])]
          (is (nil? issue))
          (is (= "M 0 0 l 10 5" (?. result 3 2 :d)))))

      (testing "[:curve-abs] emits absolute C command"
        (let [[issue result] (path-svg [[:move-abs {:x 0 :y 0}]
                                        [:curve-abs {:x1 10 :y1 20 :x2 30 :y2 40 :x 50 :y 0}]])]
          (is (nil? issue))
          (is (= "M 0 0 C 10 20 30 40 50 0" (?. result 3 2 :d)))))

      (testing "[:curve-rel] emits relative c command"
        (let [[issue result] (path-svg [[:move-abs {:x 0 :y 0}]
                                        [:curve-rel {:dx1 10 :dy1 20 :dx2 30 :dy2 40 :dx 50 :dy 0}]])]
          (is (nil? issue))
          (is (= "M 0 0 c 10 20 30 40 50 0" (?. result 3 2 :d)))))

      (testing "[:quad-abs] emits absolute Q command"
        (let [[issue result] (path-svg [[:move-abs {:x 0 :y 0}]
                                        [:quad-abs {:x1 25 :y1 50 :x 50 :y 0}]])]
          (is (nil? issue))
          (is (= "M 0 0 Q 25 50 50 0" (?. result 3 2 :d)))))

      (testing "[:quad-rel] emits relative q command"
        (let [[issue result] (path-svg [[:move-abs {:x 0 :y 0}]
                                        [:quad-rel {:dx1 25 :dy1 50 :dx 50 :dy 0}]])]
          (is (nil? issue))
          (is (= "M 0 0 q 25 50 50 0" (?. result 3 2 :d)))))

      (testing "[:arc-abs] emits absolute A command"
        (let [[issue result] (path-svg [[:move-abs {:x 10 :y 0}]
                                        [:arc-abs {:rx 20 :ry 20 :rot 0 :large-arc 0 :sweep 1 :x 50 :y 0}]])]
          (is (nil? issue))
          (is (= "M 10 0 A 20 20 0 0 1 50 0" (?. result 3 2 :d)))))

      (testing "[:arc-rel] emits relative a command"
        (let [[issue result] (path-svg [[:move-abs {:x 10 :y 0}]
                                        [:arc-rel {:rx 20 :ry 20 :rot 0 :large-arc 0 :sweep 1 :dx 40 :dy 0}]])]
          (is (nil? issue))
          (is (= "M 10 0 a 20 20 0 0 1 40 0" (?. result 3 2 :d)))))

      (testing "[:close] emits Z command"
        (let [[issue result] (path-svg [[:move-abs {:x 10 :y 20}]
                                        [:line-abs {:x 50 :y 20}]
                                        [:close {}]])]
          (is (nil? issue))
          (is (= "M 10 20 L 50 20 Z" (?. result 3 2 :d)))))

      (testing "stroke attribute is passed through"
        (let [[issue result] (path-svg [[:move-abs {:x 0 :y 0}]] {:stroke "black"})]
          (is (nil? issue))
          (is (= "black" (?. result 3 2 :stroke)))))

      (testing "stroke-width attribute is passed through"
        (let [[issue result] (path-svg [[:move-abs {:x 0 :y 0}]] {:stroke-width 2})]
          (is (nil? issue))
          (is (= 2 (?. result 3 2 :stroke-width)))))

      (testing "fill attribute is passed through"
        (let [[issue result] (path-svg [[:move-abs {:x 0 :y 0}]] {:fill "red"})]
          (is (nil? issue))
          (is (= "red" (?. result 3 2 :fill))))))

    (testing "measurement dims [:in 1] [:pt 72] → SVG doc with {:width \"1in\" :height \"72pt\"}"
      (let [[issue result] (bic.dsl {:target :svg}
                                    [:bic {:width [1 :in] :height [72 :pt]}])]
        (is (nil? issue))

        (testing "[1 :in] converts to 1in"
          (is (= "1in" (-> result (. 2) (. :width))) result))

        (testing "[72 :pt] converts to 72pt"
          (is (= "72pt" (-> result (. 2) (. :height))) result)))))

  (testing "translation to EPS"
    (testing "rect"
      (let [[issue result] (bic.dsl {:target :eps}
                                    [:bic {:width 200 :height 100}
                                     [:rect {:x 10 :y 20 :width 80 :height 40}]])]
        (is (nil? issue))
        (is (deep= [:eps {:width 200 :height 100}
                    [:rectstroke {:x 10 :y 40 :w 80 :h 40}]]
                   result))))

    (testing "rect with rx"
      (let [[issue result] (bic.dsl {:target :eps}
                                    [:bic {:width 200 :height 100}
                                     [:rect {:x 10 :y 20 :width 80 :height 40 :rx 8}]])]
        (is (nil? issue))
        (is (deep= [:eps {:width 200 :height 100}
                    [:newpath]
                    [:moveto {:x 18 :y 40}]
                    [:lineto {:x 82 :y 40}]
                    [:arc {:cx 82 :cy 48 :r 8 :a1 270 :a2 0}]
                    [:lineto {:x 90 :y 72}]
                    [:arc {:cx 82 :cy 72 :r 8 :a1 0 :a2 90}]
                    [:lineto {:x 18 :y 80}]
                    [:arc {:cx 18 :cy 72 :r 8 :a1 90 :a2 180}]
                    [:lineto {:x 10 :y 48}]
                    [:arc {:cx 18 :cy 48 :r 8 :a1 180 :a2 270}]
                    [:closepath]
                    [:stroke]]
                   result))))

    (testing "circle"
      (let [[issue result] (bic.dsl {:target :eps}
                                    [:bic {:width 200 :height 100}
                                     [:circle {:cx 50 :cy 30 :r 20}]])]
        (is (nil? issue))
        (is (deep= [:eps {:width 200 :height 100}
                    [:newpath]
                    [:arc {:cx 50 :cy 70 :r 20 :a1 0 :a2 360}]
                    [:stroke]]
                   result))))

    (testing "text"
      (let [[issue result] (bic.dsl {:target :eps}
                                    [:bic {:width 200 :height 100}
                                     [:text {:x 10 :y 20 :font "FreeSans" :size 12
                                             :str "Hi"}]])]
        (is (nil? issue))
        (is (deep= [:eps {:width 200 :height 100}
                    [:setfont {:name "FreeSans" :size 12}]
                    [:moveto {:x 10 :y (bic.eps-y 100 20)}]
                    [:show {:str "Hi"}]]
                   result)
            "Example :eps output on successful processing.")

        (let [font-output (-> result (. 3))]
          (is (= :setfont (-> font-output (. 1))) ":eps :setfont operator is set")
          (is (= "FreeSans" (-> font-output
                              (. 2)
                              (. :name)))
              "Font name is set if provided.")))

        (testing "Font name is set to default if :font attribute is absent"
          (tset _G :vic_font "FreeSans")
          (tset _G :vic_size 12)
          (let [[issue result] (bic.dsl {:target :eps}
                                        [:bic {:width 200 :height 100}
                                         [:text {:x 10 :y 20 :str "Hi"}]])]
            (tset _G :vic_font nil)
            (tset _G :vic_size nil)
            (is (nil? issue))
            (is (= "FreeSans" (?. result 3 2 :name))
                "Font name is set to default if :font attribute is absent")
            (is (= 12 (?. result 3 2 :size))
                "Font size is set to default if :size attribute is absent")))


        (testing "missing font/size with no globals still fails validation"
          (let [[issue _result] (bic.dsl {:target :eps}
                                         [:bic {:width 200 :height 100}
                                          [:text {:x 10 :y 20 :str "Hi"}]])]
            (is (= :error issue.level))))

      (testing "mixed ASCII and non-ASCII"
        (let [[issue result] (bic.dsl {:target :eps}
                                      [:bic {:width 200 :height 100}
                                       [:text {:x 10 :y 20 :font "FreeSans" :size 12
                                               :str "A☺B"}]])]
          (is (nil? issue))
          (is (deep= [:eps {:width 200 :height 100}
                      [:setfont {:name "FreeSans" :size 12}]
                      [:moveto {:x 10 :y (bic.eps-y 100 20)}]
                      [:show {:str "A"}]
                      [:glyphshow {:name "smileface"}]
                      [:show {:str "B"}]]
                     result))))
      )

    (testing "path"
      (fn path-eps [cmds ?attrs]
        (let [attrs (or ?attrs {})]
          (tset attrs :d cmds)
          (bic.dsl {:target :eps} [:bic {:width 200 :height 100} [:path attrs]])))

      (fn has-op? [result tag]
        (accumulate [found false _ node (ipairs result) &until found]
          (= tag (. node 1))))

      (testing "wraps path commands in newpath and stroke"
        (let [[issue result] (path-eps [[:move-abs {:x 10 :y 20}] [:close {}]])]
          (is (nil? issue))
          (is (= :newpath (?. result 3 1)))
          (is (= :stroke (. (. result (length result)) 1)))))

      (testing "[:move-abs] emits moveto with Y-flip"
        (let [[issue result] (path-eps [[:move-abs {:x 10 :y 20}]])]
          (is (nil? issue))
          (is (deep= [:eps {:width 200 :height 100}
                      [:newpath]
                      [:moveto {:x 10 :y 80}]
                      [:stroke]]
                     result))))

      (testing "[:move-rel] emits rmoveto with negated dy"
        (let [[issue result] (path-eps [[:move-abs {:x 0 :y 0}] [:move-rel {:dx 5 :dy 10}]])]
          (is (nil? issue))
          (is (deep= [:rmoveto {:dx 5 :dy -10}] (. result 5)))))

      (testing "[:line-abs] emits lineto with Y-flip"
        (let [[issue result] (path-eps [[:move-abs {:x 0 :y 0}] [:line-abs {:x 50 :y 30}]])]
          (is (nil? issue))
          (is (deep= [:lineto {:x 50 :y 70}] (. result 5)))))

      (testing "[:line-rel] emits rlineto with negated dy"
        (let [[issue result] (path-eps [[:move-abs {:x 0 :y 0}] [:line-rel {:dx 10 :dy 5}]])]
          (is (nil? issue))
          (is (deep= [:rlineto {:dx 10 :dy -5}] (. result 5)))))

      (testing "[:curve-abs] emits curveto with Y-flip on all y coordinates"
        (let [[issue result] (path-eps [[:move-abs {:x 0 :y 0}]
                                        [:curve-abs {:x1 10 :y1 20 :x2 30 :y2 40 :x 50 :y 0}]])]
          (is (nil? issue))
          (is (deep= [:curveto {:x1 10 :y1 80 :x2 30 :y2 60 :x3 50 :y3 100}] (. result 5)))))

      (testing "[:curve-rel] emits rcurveto with negated dy values"
        (let [[issue result] (path-eps [[:move-abs {:x 0 :y 0}]
                                        [:curve-rel {:dx1 10 :dy1 20 :dx2 30 :dy2 40 :dx 50 :dy 0}]])]
          (is (nil? issue))
          (is (deep= [:rcurveto {:dx1 10 :dy1 -20 :dx2 30 :dy2 -40 :dx3 50 :dy3 0}] (. result 5)))))

      (testing "[:quad-abs] converts quadratic bezier to cubic curveto"
        ;; P0=(0,0) P1=(30,30) P2=(60,0) → C1=(20,20) C2=(40,20) in SVG space
        ;; Y-flipped (h=100): C1y=80 C2y=80 P2y=100
        (let [[issue result] (path-eps [[:move-abs {:x 0 :y 0}]
                                        [:quad-abs {:x1 30 :y1 30 :x 60 :y 0}]])]
          (is (nil? issue))
          (is (deep= [:curveto {:x1 20 :y1 80 :x2 40 :y2 80 :x3 60 :y3 100}] (. result 5)))))

      (testing "[:quad-rel] converts relative quadratic bezier to rcurveto"
        ;; from P0=(0,0): dx1=30 dy1=30 dx=60 dy=0
        ;; C1 = 2/3*(30,30) = (20,20), C2 = (60,0)+2/3*((30,30)-(60,0)) = (40,20)
        ;; relative rcurveto: dx1=20 dy1=-20 dx2=40 dy2=-20 dx3=60 dy3=0
        (let [[issue result] (path-eps [[:move-abs {:x 0 :y 0}]
                                        [:quad-rel {:dx1 30 :dy1 30 :dx 60 :dy 0}]])]
          (is (nil? issue))
          (is (deep= [:rcurveto {:dx1 20 :dy1 -20 :dx2 40 :dy2 -20 :dx3 60 :dy3 0}] (. result 5)))))

      (testing "[:arc-abs] decomposes arc into curveto sequence"
        (let [[issue result] (path-eps [[:move-abs {:x 0 :y 50}]
                                        [:arc-abs {:rx 50 :ry 50 :rot 0 :large-arc 0 :sweep 1
                                                   :x 100 :y 50}]])]
          (is (nil? issue))
          (is (has-op? result :curveto))))

      (testing "[:arc-rel] decomposes relative arc into curveto sequence"
        (let [[issue result] (path-eps [[:move-abs {:x 0 :y 50}]
                                        [:arc-rel {:rx 50 :ry 50 :rot 0 :large-arc 0 :sweep 1
                                                   :dx 100 :dy 0}]])]
          (is (nil? issue))
          (is (has-op? result :curveto))))

      (testing "[:close] emits closepath"
        (let [[issue result] (path-eps [[:move-abs {:x 10 :y 20}]
                                        [:line-abs {:x 50 :y 20}]
                                        [:close {}]])]
          (is (nil? issue))
          (is (has-op? result :closepath))))

      (testing "fill attribute emits fill before stroke"
        (let [[issue result] (path-eps [[:move-abs {:x 0 :y 0}] [:close {}]] {:fill "black"})]
          (is (nil? issue))
          (is (has-op? result :fill))
          (is (has-op? result :stroke))))

      (testing "fill without stroke emits only fill"
        (let [[issue result] (path-eps [[:move-abs {:x 0 :y 0}] [:close {}]]
                                       {:fill "black" :stroke "none"})]
          (is (nil? issue))
          (is (has-op? result :fill))
          (is (not (has-op? result :stroke))))))

    (testing "measurements"
      (let [[issue result] (bic.dsl {:target :eps}
                                    [:bic {:width [1 :in] :height [72 :pt]}])]
        (is (nil? issue))

        (testing "[1 :in] converts to 72"
          (is (= 72 (-> result (. 2) (. :width))) result))

        (testing "[72 :pt] converts to 72"
          (is (= 72 (-> result (. 2) (. :height))) result))
        )))



  (testing "document wrapper → SVG"
    (let [[issue result] (bic.dsl {:target :svg}
                                  [:bic {:width 200 :height 100}])]
      (is (nil? issue))
      (is (deep= (svg {}) result))))

  (testing "document wrapper → EPS"
    (let [[issue result] (bic.dsl {:target :eps}
                                  [:bic {:width 200 :height 100}])]
      (is (nil? issue))
      (is (deep= [:eps {:width 200 :height 100}] result))))

  (testing "invalid dimension (string) returns :grammar/measurement error"
    (let [[issue _result] (bic.dsl [:bic {:width "bad" :height 100}])]
      (is (= :error issue.level))
      (is (= :grammar/measurement issue.type)))))

(run-tests)
