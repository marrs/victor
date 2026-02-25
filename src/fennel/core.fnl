(fn nil? [v] (= nil v))
(fn number? [v] (= :number (type v)))

{: nil? : number?}
