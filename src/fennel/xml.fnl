(fn kw->name [kw]
  (let [result (string.gsub (tostring kw) "/" ":")]
    result))

(fn escape [ss]
  (let [s1 (string.gsub ss  "&"  "&amp;")
        s2 (string.gsub s1  "<"  "&lt;")
        s3 (string.gsub s2  ">"  "&gt;")
        s4 (string.gsub s3  "\"" "&quot;")]
    s4))

(fn render-attrs [attrs]
  (let [keys []]
    (each [kk _ (pairs attrs)]
      (table.insert keys kk))
    (table.sort keys (fn [aa bb] (< (tostring aa) (tostring bb))))
    (let [parts []]
      (each [_ kk (ipairs keys)]
        (table.insert parts (.. (kw->name kk) "=\"" (escape (tostring (. attrs kk))) "\"")))
      (table.concat parts " "))))

(fn str [node]
  (let [tag         (kw->name (. node 1))
        second      (. node 2)
        has-attrs   (and (= :table (type second)) (= nil (. second 1)))
        attrs       (if has-attrs second {})
        attr-str    (render-attrs attrs)
        open        (if (= attr-str "") tag (.. tag " " attr-str))
        child-start (if has-attrs 3 2)
        body        (let [parts []]
                      (for [ii child-start (length node)]
                        (let [child (. node ii)]
                          (table.insert parts
                            (if (= :table (type child))
                              (str child)
                              (escape (tostring child))))))
                      (table.concat parts ""))]
    (if (= body "")
      (.. "<" open "/>")
      (.. "<" open ">" body "</" tag ">"))))

{: str}
