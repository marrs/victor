(fn validate [schema value]
  (let [entries {}]
    (for [ii 2 (length schema)]
      (let [entry  (. schema ii)
            key    (. entry 1)
            is-opt (= 3 (length entry))
            pred   (if is-opt (. entry 3) (. entry 2))]
        (tset entries key {:pred pred :optional is-opt})))
    (var issue nil)
    (each [key spec (pairs entries)]
      (when (and (= nil issue) (not spec.optional) (= nil (. value key)))
        (set issue {:level :error
                    :type  :validator/missing-key
                    :msg   (.. "missing required key: :" key)})))
    (when (= nil issue)
      (each [key spec (pairs entries)]
        (let [vl (. value key)]
          (when (and (= nil issue) (not= nil vl) (not (spec.pred vl)))
            (set issue {:level :error
                        :type  :validator/wrong-type
                        :msg   (.. "wrong type for key: :" key)})))))
    (when (= nil issue)
      (each [key _ (pairs value)]
        (when (and (= nil issue) (= nil (. entries key)))
          (set issue {:level :warning
                      :type  :validator/unknown-key
                      :msg   (.. "unknown key: :" key)}))))
    issue))

{: validate}
