(local validator (require :src.fennel.validator))
(local grammar (require :src.fennel.grammar))
(local eps (require :src.fennel.eps))
(local xml (require :src.fennel.xml))
(local {: nil?} (require :src.fennel.core))

(fn eps-y [height y] (- height y))

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

;;; Resolvers

(local resolvers
  {:measurement
   {:eps (fn [value]
           (if (= :number (type value))
             value
             (match (. value 2)
               :pt (. value 1)
               :in (* (. value 1) 72)
               :pc (* (. value 1) 12))))
    :svg (fn [value]
           (if (= :number (type value))
             value
             (match (. value 2)
               :pt (.. (. value 1) :pt)
               :in (.. (. value 1) :in)
               :pc (.. (. value 1) :pc))))}

   :rect
   {:svg (fn [attrs _ctx]
           [nil [[:rect attrs]]])
    :eps (fn [attrs ctx]
           (let [xpos    attrs.x
                 ysvg  attrs.y
                 wd    attrs.width
                 ht    attrs.height
                 rx    attrs.rx
                 ry    attrs.ry
                 ypos  (eps-y ctx.height (+ ysvg ht))
                 nodes []]
             (if (or rx ry)
               (let [rx (or rx ry)
                     ry (or ry rx)]
                 (if (= rx ry)
                   ;; circular corners — use arc
                   (do
                     (table.insert nodes [:newpath])
                     (table.insert nodes [:moveto {:x (+ xpos rx) :y ypos}])
                     (table.insert nodes [:lineto {:x (- (+ xpos wd) rx) :y ypos}])
                     (table.insert nodes [:arc {:cx (- (+ xpos wd) rx) :cy (+ ypos rx) :r rx :a1 270 :a2 0}])
                     (table.insert nodes [:lineto {:x (+ xpos wd) :y (- (+ ypos ht) rx)}])
                     (table.insert nodes [:arc {:cx (- (+ xpos wd) rx) :cy (- (+ ypos ht) rx) :r rx :a1 0 :a2 90}])
                     (table.insert nodes [:lineto {:x (+ xpos rx) :y (+ ypos ht)}])
                     (table.insert nodes [:arc {:cx (+ xpos rx) :cy (- (+ ypos ht) rx) :r rx :a1 90 :a2 180}])
                     (table.insert nodes [:lineto {:x xpos :y (+ ypos rx)}])
                     (table.insert nodes [:arc {:cx (+ xpos rx) :cy (+ ypos rx) :r rx :a1 180 :a2 270}])
                     (table.insert nodes [:closepath])
                     (table.insert nodes [:stroke]))
                   ;; elliptical corners — approximate with curveto
                   (let [kk 0.5523]
                     (table.insert nodes [:newpath])
                     (table.insert nodes [:moveto {:x (+ xpos rx) :y ypos}])
                     (table.insert nodes [:lineto {:x (- (+ xpos wd) rx) :y ypos}])
                     (table.insert nodes [:curveto {:x1 (- (+ xpos wd) (* kk rx)) :y1 ypos
                                                    :x2 (+ xpos wd) :y2 (+ ypos (* kk ry))
                                                    :x3 (+ xpos wd) :y3 (+ ypos ry)}])
                     (table.insert nodes [:lineto {:x (+ xpos wd) :y (- (+ ypos ht) ry)}])
                     (table.insert nodes [:curveto {:x1 (+ xpos wd) :y1 (- (+ ypos ht) (* kk ry))
                                                    :x2 (- (+ xpos wd) (* kk rx)) :y2 (+ ypos ht)
                                                    :x3 (- (+ xpos wd) rx) :y3 (+ ypos ht)}])
                     (table.insert nodes [:lineto {:x (+ xpos rx) :y (+ ypos ht)}])
                     (table.insert nodes [:curveto {:x1 (+ xpos (* kk rx)) :y1 (+ ypos ht)
                                                    :x2 xpos :y2 (- (+ ypos ht) (* kk ry))
                                                    :x3 xpos :y3 (- (+ ypos ht) ry)}])
                     (table.insert nodes [:lineto {:x xpos :y (+ ypos ry)}])
                     (table.insert nodes [:curveto {:x1 xpos :y1 (+ ypos (* kk ry))
                                                    :x2 (+ xpos (* kk rx)) :y2 ypos
                                                    :x3 (+ xpos rx) :y3 ypos}])
                     (table.insert nodes [:closepath])
                     (table.insert nodes [:stroke]))))
               ;; plain rect — rectfill / rectstroke
               (do
                 (when attrs.fill
                   (let [rgb (. named-colors attrs.fill)]
                     (when rgb
                       (table.insert nodes [:setrgbcolor rgb])
                       (table.insert nodes [:rectfill {:x xpos :y ypos :w wd :h ht}]))))
                 (when (or attrs.stroke (not attrs.fill))
                   (when attrs.stroke
                     (let [rgb (. named-colors attrs.stroke)]
                       (when rgb
                         (table.insert nodes [:setrgbcolor rgb]))))
                   (when attrs.stroke-width
                     (table.insert nodes [:setlinewidth {:w attrs.stroke-width}]))
                   (table.insert nodes [:rectstroke {:x xpos :y ypos :w wd :h ht}]))))
             [nil nodes]))}

   :text
   {:svg (fn [attrs _ctx]
           [nil [[:text {:x           attrs.x
                         :y           attrs.y
                         :font-family attrs.font
                         :font-size   attrs.size}
                  attrs.str]]])
    :eps (fn [attrs ctx]
           (let [nodes []
                 ypos  (eps-y ctx.height attrs.y)]
             (table.insert nodes [:setfont {:name attrs.font :size attrs.size}])
             (table.insert nodes [:moveto {:x attrs.x :y ypos}])
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
           (let [cypos  (eps-y ctx.height attrs.cy)
                 arc-op {:cx attrs.cx :cy cypos :r attrs.r :a1 0 :a2 360}
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

;;; Schema

(local schema
  {:rect   {:schema grammar.rect   :resolver resolvers.rect}
   :circle {:schema grammar.circle :resolver resolvers.circle}
   :text   {:schema grammar.text   :resolver resolvers.text}})

;;; Attribute resolver

(fn resolve-attrs [prim-schema attrs target]
  (let [resolved {}]
    (each [key val (pairs attrs)]
      (tset resolved key val))
    (for [ii 2 (length prim-schema)]
      (let [entry      (. prim-schema ii)
            key        (. entry 1)
            has-opts   (= 3 (length entry))
            sub-schema (if has-opts (. entry 3) (. entry 2))]
        (when (and (= sub-schema grammar.measurement) (not= nil (. attrs key)))
          (tset resolved key ((. resolvers.measurement target) (. attrs key))))))
    resolved))

;;; DSL

(fn dsl [opts node]
  (local node (if (nil? node) opts node))
  (local opts (if (nil? node) {} opts))
  (let [tag    (?. node 1)
        attrs  (?. node 2)
        target (or opts.target :eps)]
    (when (not= tag :bic)
      (error (.. "bic: expected :bic tag, got " (tostring tag))))
    (let [bic-issue (validator.validate grammar.bic attrs)]
      (if bic-issue
        [bic-issue nil]
        (let [resolved-bic (resolve-attrs grammar.bic attrs target)
              ctx          {:width resolved-bic.width :height resolved-bic.height
                            :font  _G.vic_font
                            :size  _G.vic_size}
              children     []]
          (var issue nil)
          (for [idx 3 (length node) &until issue]
            (let [child      (. node idx)
                  prim-tag   (. child 1)
                  prim-attrs (. child 2)
                  prim-entry (. schema prim-tag)]
              (let [prim-attrs (if (= prim-tag :text)
                                 (let [merged {}]
                                   (each [ky vl (pairs prim-attrs)] (tset merged ky vl))
                                   (when (and (= nil merged.font) ctx.font)
                                     (tset merged :font ctx.font))
                                   (when (and (= nil merged.size) ctx.size)
                                     (tset merged :size ctx.size))
                                   merged)
                                 prim-attrs)]
                (when (= nil prim-entry)
                  (set issue {:level :error
                              :type  :bic/unknown-primitive
                              :msg   (.. "unknown primitive: " (tostring prim-tag))}))
                (when (= nil issue)
                  (let [val-issue (validator.validate prim-entry.schema prim-attrs)]
                    (when val-issue (set issue val-issue))))
                (when (= nil issue)
                  (let [resolved-prim (resolve-attrs prim-entry.schema prim-attrs target)
                        [tr-issue nodes] ((. prim-entry.resolver target) resolved-prim ctx)]
                    (when tr-issue (set issue tr-issue))
                    (each [_ x (ipairs nodes)]
                      (table.insert children x)))))))
          (if issue
            [issue nil]
            (let [doc (if (= target :svg)
                        [:svg {:xmlns "http://www.w3.org/2000/svg"
                               :width resolved-bic.width :height resolved-bic.height}]
                        [:eps {:width resolved-bic.width :height resolved-bic.height}])]
              (each [_ child (ipairs children)]
                (table.insert doc child))
              [nil doc])))))))

(fn render [opts node]
  (let [[err output] (dsl opts node)]
    (if err (error (string.format "%s: %s" err.type err.msg) 2)
      (if (= :eps (. output 1))
        (eps.str output)
        (xml.str output)))))


{: eps-y : dsl : render}
