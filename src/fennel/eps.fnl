(local ops
  {:fill          []
   :stroke        []
   :eofill        []
   :closepath     []
   :newpath       []
   :clip          []
   :gsave         []
   :grestore      []
   :showpage      []
   :flattenpath   []
   :strokepath    []
   :moveto        [:x :y]
   :lineto        [:x :y]
   :rmoveto       [:dx :dy]
   :rlineto       [:dx :dy]
   :arc           [:cx :cy :r :a1 :a2]
   :arcn          [:cx :cy :r :a1 :a2]
   :curveto       [:x1 :y1 :x2 :y2 :x3 :y3]
   :rcurveto      [:dx1 :dy1 :dx2 :dy2 :dx3 :dy3]
   :setrgbcolor   [:r :g :b]
   :setgray       [:v]
   :setlinewidth  [:w]
   :setlinecap    [:cap]
   :setlinejoin   [:join]
   :setmiterlimit [:limit]
   :setdash       [:array :offset]
   :rectfill      [:x :y :w :h]
   :rectstroke    [:x :y :w :h]
   :translate     [:tx :ty]
   :rotate        [:angle]
   :scale         [:sx :sy]})

(fn str [node]
  (let [tag       (. node 1)
        second    (. node 2)
        has-attrs (and (= :table (type second)) (= nil (. second 1)))
        attrs     (if has-attrs second {})]
    (if (= tag :eps)
      (let [width  attrs.width
            height attrs.height
            header (.. "%!PS-Adobe-3.0 EPSF-3.0\n%%BoundingBox: 0 0 " width " " height "\n%%EndComments")
            parts  [header]]
        (for [x 3 (length node)]
          (table.insert parts (str (. node x))))
        (table.insert parts "%%EOF")
        (table.concat parts "\n"))
      (let [arg-keys (. ops tag)]
        (when (= nil arg-keys)
          (error (.. "eps: unknown operator: " (tostring tag))))
        (each [ky _ (pairs attrs)]
          (var found false)
          (each [_ spec-key (ipairs arg-keys)]
            (when (= spec-key ky)
              (set found true)))
          (when (not found)
            (io.stderr:write (.. "eps: warning: extra key " (tostring ky) " for " (tostring tag) "\n"))))
        (let [parts []]
          (each [_ ky (ipairs arg-keys)]
            (let [vl (. attrs ky)]
              (when (= nil vl)
                (error (.. "eps: missing required argument " (tostring ky) " for " (tostring tag))))
              (table.insert parts (tostring vl))))
          (table.insert parts (tostring tag))
          (table.concat parts " "))))))

{: str}
