(fn nil? [v] (= nil v))
(fn number? [v] (= :number (type v)))
(fn string? [v] (= :string (type v)))

(fn deep= [a b]
  (if (not= (type a) (type b))
    false
    (if (not= :table (type a))
      (= a b)
      (do
        (var eq true)
        (each [k v (pairs a)]
          (when (not (deep= v (. b k)))
            (set eq false)))
        (each [k _ (pairs b)]
          (when (= nil (. a k))
            (set eq false)))
        eq))))

{: nil? : number? : string? : deep=}
