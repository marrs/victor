(fn valid? [schema value]
  (if (= :function (type schema))
    (schema value)
    (= :enum (. schema 1))
    (do
      (var found false)
      (for [idx 2 (length schema) &until found]
        (when (= value (. schema idx))
          (set found true)))
      found)
    (= :tuple (. schema 1))
    (if (not= :table (type value))
      false
      (let [expected-len (- (length schema) 1)]
        (if (not= expected-len (length value))
          false
          (do
            (var ok true)
            (for [idx 1 expected-len &until (not ok)]
              (when (not (valid? (. schema (+ idx 1)) (. value idx)))
                (set ok false)))
            ok))))
    (= :or (. schema 1))
    (do
      (var found false)
      (for [idx 2 (length schema) &until found]
        (when (valid? (. schema idx) value)
          (set found true)))
      found)
    false))

(fn validate [schema value]
  (let [entries {}]
    (for [idx 2 (length schema)]
      (let [entry      (. schema idx)
            key        (. entry 1)
            has-opts   (= 3 (length entry))
            opts       (if has-opts (. entry 2) {})
            sub-schema (if has-opts (. entry 3) (. entry 2))]
        (tset entries key {:schema     sub-schema
                           :optional   (or opts.optional false)
                           :error-type (or opts.error-type :validator/wrong-type)})))
    (var issue nil)
    (each [key spec (pairs entries)]
      (when (and (= nil issue) (not spec.optional) (= nil (. value key)))
        (set issue {:level :error
                    :type  :validator/missing-key
                    :msg   (.. "missing required key: :" key)})))
    (when (= nil issue)
      (each [key spec (pairs entries)]
        (let [vl (. value key)]
          (when (and (= nil issue) (not= nil vl) (not (valid? spec.schema vl)))
            (set issue {:level :error
                        :type  spec.error-type
                        :msg   (.. "wrong type for key: :" key)})))))
    (when (= nil issue)
      (each [key _ (pairs value)]
        (when (and (= nil issue) (= nil (. entries key)))
          (set issue {:level :warning
                      :type  :validator/unknown-key
                      :msg   (.. "unknown key: :" key)}))))
    issue))

{: validate}
