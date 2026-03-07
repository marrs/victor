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

   :path
   (let [path-d
         (fn [cmds]
           (let [parts []]
             (each [_ cmd (ipairs cmds)]
               (let [tag (. cmd 1) aa (. cmd 2)]
                 (match tag
                   :move-abs  (table.insert parts (.. "M " aa.x " " aa.y))
                   :move-rel  (table.insert parts (.. "m " aa.dx " " aa.dy))
                   :line-abs  (table.insert parts (.. "L " aa.x " " aa.y))
                   :line-rel  (table.insert parts (.. "l " aa.dx " " aa.dy))
                   :curve-abs (table.insert parts (.. "C " aa.x1 " " aa.y1 " " aa.x2 " " aa.y2 " " aa.x " " aa.y))
                   :curve-rel (table.insert parts (.. "c " aa.dx1 " " aa.dy1 " " aa.dx2 " " aa.dy2 " " aa.dx " " aa.dy))
                   :quad-abs  (table.insert parts (.. "Q " aa.x1 " " aa.y1 " " aa.x " " aa.y))
                   :quad-rel  (table.insert parts (.. "q " aa.dx1 " " aa.dy1 " " aa.dx " " aa.dy))
                   :arc-abs   (table.insert parts (.. "A " aa.rx " " aa.ry " " aa.rot " " aa.large-arc " " aa.sweep " " aa.x " " aa.y))
                   :arc-rel   (table.insert parts (.. "a " aa.rx " " aa.ry " " aa.rot " " aa.large-arc " " aa.sweep " " aa.dx " " aa.dy))
                   :close     (table.insert parts "Z"))))
             (table.concat parts " ")))

         arc->beziers
         (fn [x1 y1 rx ry rot large-arc sweep x2 y2]
           ;; Convert SVG endpoint arc to cubic Bézier segments.
           ;; Returns list of {:x1 :y1 :x2 :y2 :x3 :y3} in SVG space.
           (let [pi       math.pi
                 phi      (* rot (/ pi 180))
                 cosp     (math.cos phi)
                 sinp     (math.sin phi)
                 ;; Step 1: midpoint in rotated frame
                 mx       (/ (- x1 x2) 2)
                 my       (/ (- y1 y2) 2)
                 x1p      (+ (* cosp mx) (* sinp my))
                 y1p      (+ (* (- sinp) mx) (* cosp my))
                 ;; Ensure radii large enough
                 rx       (math.abs rx)
                 ry       (math.abs ry)
                 lam      (+ (^ (/ x1p rx) 2) (^ (/ y1p ry) 2))
                 rx       (if (> lam 1) (* rx (math.sqrt lam)) rx)
                 ry       (if (> lam 1) (* ry (math.sqrt lam)) ry)
                 ;; Step 2: center in rotated frame
                 num      (- (* rx rx ry ry) (* rx rx y1p y1p) (* ry ry x1p x1p))
                 den      (+ (* rx rx y1p y1p) (* ry ry x1p x1p))
                 sq       (if (> den 0) (math.sqrt (math.max 0 (/ num den))) 0)
                 sq       (if (= large-arc sweep) (- sq) sq)
                 cxp      (* sq (/ (* rx y1p) ry))
                 cyp      (* sq (- (/ (* ry x1p) rx)))
                 ;; Step 3: center in original frame
                 cx       (+ (* cosp cxp) (* (- sinp) cyp) (/ (+ x1 x2) 2))
                 cy       (+ (* sinp cxp) (* cosp cyp) (/ (+ y1 y2) 2))
                 vec-angle (fn [ux uy vx vy]
                              (let [dot (+ (* ux vx) (* uy vy))
                                    len (* (math.sqrt (+ (* ux ux) (* uy uy)))
                                           (math.sqrt (+ (* vx vx) (* vy vy))))
                                    ang (math.acos (math.max -1 (math.min 1 (/ dot len))))]
                                (if (< (- (* ux vy) (* uy vx)) 0) (- ang) ang)))
                 theta1   (vec-angle 1 0 (/ (- x1p cxp) rx) (/ (- y1p cyp) ry))
                 dtheta   (vec-angle (/ (- x1p cxp) rx) (/ (- y1p cyp) ry)
                                     (/ (- (- x1p) cxp) rx) (/ (- (- y1p) cyp) ry))
                 dtheta   (if (and (= sweep 0) (> dtheta 0)) (- dtheta (* 2 pi))
                              (and (= sweep 1) (< dtheta 0)) (+ dtheta (* 2 pi))
                              dtheta)
                 n-segs   (math.max 1 (math.ceil (/ (math.abs dtheta) (/ pi 2))))
                 dt       (/ dtheta n-segs)
                 alpha    (* (/ 4 3) (math.tan (/ dt 4)))
                 rot+tr   (fn [px py]
                            [(+ (* cosp px) (* (- sinp) py) cx)
                             (+ (* sinp px) (* cosp py) cy)])
                 segs     []]
             (for [ii 0 (- n-segs 1)]
               (let [t1       (+ theta1 (* ii dt))
                     t2       (+ theta1 (* (+ ii 1) dt))
                     p1x      (* rx (math.cos t1))
                     p1y      (* ry (math.sin t1))
                     p2x      (* rx (math.cos t2))
                     p2y      (* ry (math.sin t2))
                     d1x      (- (* rx (math.sin t1)))
                     d1y      (* ry (math.cos t1))
                     d2x      (- (* rx (math.sin t2)))
                     d2y      (* ry (math.cos t2))
                     c1x      (+ p1x (* alpha d1x))
                     c1y      (+ p1y (* alpha d1y))
                     c2x      (- p2x (* alpha d2x))
                     c2y      (- p2y (* alpha d2y))
                     [c1rx c1ry] (rot+tr c1x c1y)
                     [c2rx c2ry] (rot+tr c2x c2y)
                     [p2rx p2ry] (rot+tr p2x p2y)]
                 (table.insert segs {:x1 c1rx :y1 c1ry
                                     :x2 c2rx :y2 c2ry
                                     :x3 p2rx :y3 p2ry})))
             segs))

         emit-eps-cmds
         (fn [nodes height cmds]
           (var cur-x 0)
           (var cur-y 0)
           (each [_ cmd (ipairs cmds)]
             (let [tag (. cmd 1) aa (. cmd 2)]
               (match tag
                 :move-abs (do
                             (table.insert nodes [:moveto {:x aa.x :y (eps-y height aa.y)}])
                             (set cur-x aa.x)
                             (set cur-y aa.y))
                 :move-rel (do
                             (table.insert nodes [:rmoveto {:dx aa.dx :dy (- aa.dy)}])
                             (set cur-x (+ cur-x aa.dx))
                             (set cur-y (+ cur-y aa.dy)))
                 :line-abs (do
                             (table.insert nodes [:lineto {:x aa.x :y (eps-y height aa.y)}])
                             (set cur-x aa.x)
                             (set cur-y aa.y))
                 :line-rel (do
                             (table.insert nodes [:rlineto {:dx aa.dx :dy (- aa.dy)}])
                             (set cur-x (+ cur-x aa.dx))
                             (set cur-y (+ cur-y aa.dy)))
                 :curve-abs (do
                              (table.insert nodes [:curveto {:x1 aa.x1 :y1 (eps-y height aa.y1)
                                                             :x2 aa.x2 :y2 (eps-y height aa.y2)
                                                             :x3 aa.x  :y3 (eps-y height aa.y)}])
                              (set cur-x aa.x)
                              (set cur-y aa.y))
                 :curve-rel (do
                              (table.insert nodes [:rcurveto {:dx1 aa.dx1 :dy1 (- aa.dy1)
                                                              :dx2 aa.dx2 :dy2 (- aa.dy2)
                                                              :dx3 aa.dx  :dy3 (- aa.dy)}])
                              (set cur-x (+ cur-x aa.dx))
                              (set cur-y (+ cur-y aa.dy)))
                 :quad-abs (let [;; P0=cur, P1=(x1,y1), P2=(x,y)
                                 ;; C1 = P0 + 2/3*(P1-P0), C2 = P2 + 2/3*(P1-P2)
                                 c1x (+ cur-x (* (/ 2 3) (- aa.x1 cur-x)))
                                 c1y (+ cur-y (* (/ 2 3) (- aa.y1 cur-y)))
                                 c2x (+ aa.x  (* (/ 2 3) (- aa.x1 aa.x)))
                                 c2y (+ aa.y  (* (/ 2 3) (- aa.y1 aa.y)))]
                             (table.insert nodes [:curveto {:x1 c1x :y1 (eps-y height c1y)
                                                            :x2 c2x :y2 (eps-y height c2y)
                                                            :x3 aa.x :y3 (eps-y height aa.y)}])
                             (set cur-x aa.x)
                             (set cur-y aa.y))
                 :quad-rel (let [;; relative: dC1 = 2/3*(dx1,dy1)
                                 ;;           dC2 = ((dx+2*dx1)/3, (dy+2*dy1)/3)
                                 dc1x (* (/ 2 3) aa.dx1)
                                 dc1y (* (/ 2 3) aa.dy1)
                                 dc2x (/ (+ aa.dx (* 2 aa.dx1)) 3)
                                 dc2y (/ (+ aa.dy (* 2 aa.dy1)) 3)]
                             (table.insert nodes [:rcurveto {:dx1 dc1x :dy1 (- dc1y)
                                                             :dx2 dc2x :dy2 (- dc2y)
                                                             :dx3 aa.dx :dy3 (- aa.dy)}])
                             (set cur-x (+ cur-x aa.dx))
                             (set cur-y (+ cur-y aa.dy)))
                 :arc-abs (let [segs (arc->beziers cur-x cur-y aa.rx aa.ry aa.rot aa.large-arc aa.sweep aa.x aa.y)]
                            (each [_ seg (ipairs segs)]
                              (table.insert nodes [:curveto {:x1 seg.x1 :y1 (eps-y height seg.y1)
                                                             :x2 seg.x2 :y2 (eps-y height seg.y2)
                                                             :x3 seg.x3 :y3 (eps-y height seg.y3)}]))
                            (set cur-x aa.x)
                            (set cur-y aa.y))
                 :arc-rel (let [segs (arc->beziers cur-x cur-y aa.rx aa.ry aa.rot aa.large-arc aa.sweep
                                                   (+ cur-x aa.dx) (+ cur-y aa.dy))]
                            (each [_ seg (ipairs segs)]
                              (table.insert nodes [:curveto {:x1 seg.x1 :y1 (eps-y height seg.y1)
                                                             :x2 seg.x2 :y2 (eps-y height seg.y2)
                                                             :x3 seg.x3 :y3 (eps-y height seg.y3)}]))
                            (set cur-x (+ cur-x aa.dx))
                            (set cur-y (+ cur-y aa.dy)))
                 :close (table.insert nodes [:closepath])))))]
     {:svg (fn [attrs _ctx]
             [nil [[:path {:d      (path-d attrs.d)
                           :fill   attrs.fill
                           :stroke attrs.stroke
                           :stroke-width attrs.stroke-width}]]])
      :eps (fn [attrs ctx]
             (let [height    ctx.height
                   nodes     []
                   do-fill   (and attrs.fill (not= attrs.fill :none))
                   do-stroke (not= attrs.stroke :none)]
               (table.insert nodes [:gsave])
               (when do-fill
                 (table.insert nodes [:newpath])
                 (emit-eps-cmds nodes height attrs.d)
                 (when (. named-colors attrs.fill)
                   (table.insert nodes [:setrgbcolor (. named-colors attrs.fill)]))
                 (table.insert nodes [:fill]))
               (when do-stroke
                 (table.insert nodes [:newpath])
                 (emit-eps-cmds nodes height attrs.d)
                 (when (and attrs.stroke (. named-colors attrs.stroke))
                   (table.insert nodes [:setrgbcolor (. named-colors attrs.stroke)]))
                 (when attrs.stroke-width
                   (table.insert nodes [:setlinewidth {:w attrs.stroke-width}]))
                 (table.insert nodes [:stroke]))
               (table.insert nodes [:grestore])
               [nil nodes]))})

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
   :text   {:schema grammar.text   :resolver resolvers.text}
   :path   {:schema grammar.path
            :resolver resolvers.path}})

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
                  prim-entry (. schema prim-tag)
                  second     (. child 2)
                  has-attrs  (and (= :table (type second)) (= nil (. second 1)))
                  prim-attrs (if has-attrs second {})
                  cmd-start  (if has-attrs 3 2)]
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
                  (let [resolved-prim (resolve-attrs prim-entry.schema prim-attrs target)]
                    (when (= prim-tag :path)
                      (let [cmds []]
                        (for [ci cmd-start (length child)]
                          (table.insert cmds (. child ci)))
                        (tset resolved-prim :d cmds)))
                    (let [[tr-issue nodes] ((. prim-entry.resolver target) resolved-prim ctx)]
                      (when tr-issue (set issue tr-issue))
                      (each [_ x (ipairs nodes)]
                        (table.insert children x))))))))
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
