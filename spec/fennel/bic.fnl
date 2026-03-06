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
