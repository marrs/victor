(local xml (require :src.fennel.xml))

(local smiley
  [:svg {:xmlns   "http://www.w3.org/2000/svg"
         :viewBox "0 0 100 120"
         :width   "100"
         :height  "120"}
   [:rect {:x "0" :y "0" :width "100" :height "120" :fill "white"}]
   [:circle {:cx "50" :cy "50" :r "45"
             :fill "yellow" :stroke "black" :stroke-width "2"}]
   [:circle {:cx "35" :cy "40" :r "5" :fill "black"}]
   [:circle {:cx "65" :cy "40" :r "5" :fill "black"}]
   [:path   {:d "M 30 60 Q 50 80 70 60"
             :fill "none" :stroke "black" :stroke-width "3"}]
   [:text   {:x "8" :y "115" :font-family "NanumGothic" :font-size "8"}
            "Hello, World! ☺"]])

(print (xml.str smiley))
