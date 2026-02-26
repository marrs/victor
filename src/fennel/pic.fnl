(local validator (require :src.fennel.validator))
(local {: number? : string?} (require :src.fennel.core))

(fn eps-y [height y] (- height y))

;;; Schema

(local schema
  {:rect   [:map
            [:x            number?]
            [:y            number?]
            [:width        number?]
            [:height       number?]
            [:rx           {:optional true} number?]
            [:ry           {:optional true} number?]
            [:fill         {:optional true} string?]
            [:stroke       {:optional true} string?]
            [:stroke-width {:optional true} number?]]
   :circle [:map
            [:cx           number?]
            [:cy           number?]
            [:r            number?]
            [:fill         {:optional true} string?]
            [:stroke       {:optional true} string?]
            [:stroke-width {:optional true} number?]]
   :text   [:map
            [:x    number?]
            [:y    number?]
            [:font string?]
            [:size number?]
            [:str  string?]]})

;;; Color

(local named-colors
  {:black   {:r 0 :g 0 :b 0}
   :white   {:r 1 :g 1 :b 1}
   :red     {:r 1 :g 0 :b 0}
   :green   {:r 0 :g 1 :b 0}
   :blue    {:r 0 :g 0 :b 1}
   :yellow  {:r 1 :g 1 :b 0}
   :cyan    {:r 0 :g 1 :b 1}
   :magenta {:r 1 :g 0 :b 1}})

;;; Translators

(local translators
  {:rect
   {:svg (fn [attrs _ctx]
           [nil [[:rect attrs]]])
    :eps (fn [attrs ctx]
           (let [xx    attrs.x
                 ysvg  attrs.y
                 ww    attrs.width
                 hh    attrs.height
                 rx    attrs.rx
                 ry    attrs.ry
                 yeps  (eps-y ctx.height (+ ysvg hh))
                 nodes []]
             (if (or rx ry)
               (let [rx (or rx ry)
                     ry (or ry rx)]
                 (if (= rx ry)
                   ;; circular corners — use arc
                   (do
                     (table.insert nodes [:newpath])
                     (table.insert nodes [:moveto {:x (+ xx rx) :y yeps}])
                     (table.insert nodes [:lineto {:x (- (+ xx ww) rx) :y yeps}])
                     (table.insert nodes [:arc {:cx (- (+ xx ww) rx) :cy (+ yeps rx) :r rx :a1 270 :a2 0}])
                     (table.insert nodes [:lineto {:x (+ xx ww) :y (- (+ yeps hh) rx)}])
                     (table.insert nodes [:arc {:cx (- (+ xx ww) rx) :cy (- (+ yeps hh) rx) :r rx :a1 0 :a2 90}])
                     (table.insert nodes [:lineto {:x (+ xx rx) :y (+ yeps hh)}])
                     (table.insert nodes [:arc {:cx (+ xx rx) :cy (- (+ yeps hh) rx) :r rx :a1 90 :a2 180}])
                     (table.insert nodes [:lineto {:x xx :y (+ yeps rx)}])
                     (table.insert nodes [:arc {:cx (+ xx rx) :cy (+ yeps rx) :r rx :a1 180 :a2 270}])
                     (table.insert nodes [:closepath])
                     (table.insert nodes [:stroke]))
                   ;; elliptical corners — approximate with curveto
                   (let [kk 0.5523]
                     (table.insert nodes [:newpath])
                     (table.insert nodes [:moveto {:x (+ xx rx) :y yeps}])
                     (table.insert nodes [:lineto {:x (- (+ xx ww) rx) :y yeps}])
                     (table.insert nodes [:curveto {:x1 (- (+ xx ww) (* kk rx)) :y1 yeps
                                                    :x2 (+ xx ww) :y2 (+ yeps (* kk ry))
                                                    :x3 (+ xx ww) :y3 (+ yeps ry)}])
                     (table.insert nodes [:lineto {:x (+ xx ww) :y (- (+ yeps hh) ry)}])
                     (table.insert nodes [:curveto {:x1 (+ xx ww) :y1 (- (+ yeps hh) (* kk ry))
                                                    :x2 (- (+ xx ww) (* kk rx)) :y2 (+ yeps hh)
                                                    :x3 (- (+ xx ww) rx) :y3 (+ yeps hh)}])
                     (table.insert nodes [:lineto {:x (+ xx rx) :y (+ yeps hh)}])
                     (table.insert nodes [:curveto {:x1 (+ xx (* kk rx)) :y1 (+ yeps hh)
                                                    :x2 xx :y2 (- (+ yeps hh) (* kk ry))
                                                    :x3 xx :y3 (- (+ yeps hh) ry)}])
                     (table.insert nodes [:lineto {:x xx :y (+ yeps ry)}])
                     (table.insert nodes [:curveto {:x1 xx :y1 (+ yeps (* kk ry))
                                                    :x2 (+ xx (* kk rx)) :y2 yeps
                                                    :x3 (+ xx rx) :y3 yeps}])
                     (table.insert nodes [:closepath])
                     (table.insert nodes [:stroke]))))
               ;; plain rect — rectfill / rectstroke
               (do
                 (when attrs.fill
                   (let [rgb (. named-colors attrs.fill)]
                     (when rgb
                       (table.insert nodes [:setrgbcolor rgb])
                       (table.insert nodes [:rectfill {:x xx :y yeps :w ww :h hh}]))))
                 (when (or attrs.stroke (not attrs.fill))
                   (when attrs.stroke
                     (let [rgb (. named-colors attrs.stroke)]
                       (when rgb
                         (table.insert nodes [:setrgbcolor rgb]))))
                   (when attrs.stroke-width
                     (table.insert nodes [:setlinewidth {:w attrs.stroke-width}]))
                   (table.insert nodes [:rectstroke {:x xx :y yeps :w ww :h hh}]))))
             [nil nodes]))}

   :text
   {:svg (fn [attrs _ctx]
           [nil [[:text {:x          attrs.x
                         :y          attrs.y
                         :font-family attrs.font
                         :font-size  attrs.size}
                  attrs.str]]])
    :eps (fn [attrs ctx]
           (let [nodes []
                 yeps  (eps-y ctx.height attrs.y)]
             (table.insert nodes [:setfont {:name attrs.font :size attrs.size}])
             (table.insert nodes [:moveto {:x attrs.x :y yeps}])
             (var run [])
             (fn flush-run []
               (when (> (length run) 0)
                 (table.insert nodes [:show {:str (table.concat run)}])
                 (set run [])))
             (each [_ cp (utf8.codes attrs.str)]
               (if (and (>= cp 0x20) (<= cp 0x7E))
                 (table.insert run (string.char cp))
                 (do
                   (flush-run)
                   (let [(err name) (glyph_name attrs.font cp)
                         agl-name  (if (<= cp 0xFFFF)
                                     (string.format "uni%04X" cp)
                                     (string.format "u%X" cp))
                         gname     (if (or (not name) (= name ""))
                                     agl-name
                                     name)]
                     (table.insert nodes [:glyphshow {:name gname}])))))
             (flush-run)
             [nil nodes]))}

   :circle
   {:svg (fn [attrs _ctx]
           [nil [[:circle attrs]]])
    :eps (fn [attrs ctx]
           (let [cyeps  (eps-y ctx.height attrs.cy)
                 arc-op {:cx attrs.cx :cy cyeps :r attrs.r :a1 0 :a2 360}
                 nodes  []]
             ;; Fill pass
             (when attrs.fill
               (let [rgb (. named-colors attrs.fill)]
                 (when rgb
                   (table.insert nodes [:newpath])
                   (table.insert nodes [:arc arc-op])
                   (table.insert nodes [:setrgbcolor rgb])
                   (table.insert nodes [:fill]))))
             ;; Stroke pass (explicit stroke, or bare stroke when no fill specified)
             (when (or attrs.stroke (not attrs.fill))
               (table.insert nodes [:newpath])
               (table.insert nodes [:arc arc-op])
               (when attrs.stroke
                 (let [rgb (. named-colors attrs.stroke)]
                   (when rgb
                     (table.insert nodes [:setrgbcolor rgb]))))
               (when attrs.stroke-width
                 (table.insert nodes [:setlinewidth {:w attrs.stroke-width}]))
               (table.insert nodes [:stroke]))
             [nil nodes]))}})

;;; render

(fn render [opts node]
  (let [tag    (. node 1)
        attrs  (. node 2)
        target opts.target]
    (when (not= tag :pic)
      (error (.. "pic: expected :pic tag, got " (tostring tag))))
    (let [ctx      {:width attrs.width :height attrs.height}
          children []]
      (var issue nil)
      (for [ii 3 (length node) &until issue]
        (let [child      (. node ii)
              prim-tag   (. child 1)
              prim-attrs (. child 2)
              prim-schema (. schema prim-tag)]
          (when (= nil prim-schema)
            (set issue {:level :error
                        :type  :pic/unknown-primitive
                        :msg   (.. "unknown primitive: " (tostring prim-tag))}))
          (when (= nil issue)
            (let [val-issue (validator.validate prim-schema prim-attrs)]
              (when val-issue (set issue val-issue))))
          (when (= nil issue)
            (let [translator (. (. translators prim-tag) target)
                  [tr-issue nodes] (translator prim-attrs ctx)]
              (when tr-issue (set issue tr-issue))
              (each [_ nn (ipairs nodes)]
                (table.insert children nn))))))
      (if issue
        [issue nil]
        (let [doc (if (= target :svg)
                    [:svg {:xmlns "http://www.w3.org/2000/svg"
                           :width attrs.width :height attrs.height}]
                    [:eps {:width attrs.width :height attrs.height}])]
          (each [_ child (ipairs children)]
            (table.insert doc child))
          [nil doc])))))

{: eps-y : render}
