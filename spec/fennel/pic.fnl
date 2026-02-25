(import-macros {: deftest : is : run-tests : testing : are} :src.fennel.test)
(local pic (require :src.fennel.pic))
(local {: nil? : deep=} (require :src.fennel.core))

(fn svg [attrs ...]
  (let [merged {:xmlns "http://www.w3.org/2000/svg" :width 200 :height 100}
        node   [:svg merged]]
    (each [k v (pairs attrs)]
      (tset merged k v))
    (each [_ child (ipairs [...])]
      (table.insert node child))
    node))

(deftest pic.eps-y
  (are [y result] (= result (pic.eps-y 101 y))
    0   101   ;; SVG origin maps to top of EPS page
    101 0     ;; SVG bottom maps to EPS origin
    50  51    ;; near-halfway: odd height exposes rounding errors
    30  71))  ;; arbitrary value

(deftest render
  (testing "rect → SVG"
    (let [[issue result] (pic.render {:target :svg}
                                     [:pic {:width 200 :height 100}
                                      [:rect {:x 10 :y 20 :width 80 :height 40}]])]
      (is (nil? issue))
      (is (deep= (svg {} [:rect {:x 10 :y 20 :width 80 :height 40}])
                 result))))

  (testing "rect with rx → SVG passthrough"
    (let [[issue result] (pic.render {:target :svg}
                                     [:pic {:width 200 :height 100}
                                      [:rect {:x 10 :y 20 :width 80 :height 40 :rx 8}]])]
      (is (nil? issue))
      (is (deep= (svg {} [:rect {:x 10 :y 20 :width 80 :height 40 :rx 8}])
                 result))))

  (testing "circle → SVG"
    (let [[issue result] (pic.render {:target :svg}
                                     [:pic {:width 200 :height 100}
                                      [:circle {:cx 50 :cy 50 :r 30}]])]
      (is (nil? issue))
      (is (deep= (svg {} [:circle {:cx 50 :cy 50 :r 30}])
                 result))))

  (testing "rect → EPS with y-flip"
    (let [[issue result] (pic.render {:target :eps}
                                     [:pic {:width 200 :height 100}
                                      [:rect {:x 10 :y 20 :width 80 :height 40}]])]
      (is (nil? issue))
      (is (deep= [:eps {:width 200 :height 100}
                  [:rectstroke {:x 10 :y 40 :w 80 :h 40}]]
                 result))))

  (testing "rect with rx → EPS path decomposition"
    (let [[issue result] (pic.render {:target :eps}
                                     [:pic {:width 200 :height 100}
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

  (testing "circle → EPS with y-flip"
    (let [[issue result] (pic.render {:target :eps}
                                     [:pic {:width 200 :height 100}
                                      [:circle {:cx 50 :cy 30 :r 20}]])]
      (is (nil? issue))
      (is (deep= [:eps {:width 200 :height 100}
                  [:newpath]
                  [:arc {:cx 50 :cy 70 :r 20 :a1 0 :a2 360}]
                  [:stroke]]
                 result))))

  (testing "document wrapper → SVG"
    (let [[issue result] (pic.render {:target :svg}
                                     [:pic {:width 200 :height 100}])]
      (is (nil? issue))
      (is (deep= (svg {}) result))))

  (testing "document wrapper → EPS"
    (let [[issue result] (pic.render {:target :eps}
                                     [:pic {:width 200 :height 100}])]
      (is (nil? issue))
      (is (deep= [:eps {:width 200 :height 100}] result)))))

(run-tests)
