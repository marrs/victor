(import-macros {: deftest : is : run-tests : testing} :src.fennel.test)
(local grammar (require :src.fennel.grammar))
(local validator (require :src.fennel.validator))
(local {: nil?} (require :src.fennel.core))

(deftest grammar.measurement
  (testing "valid"
    (testing ":pt tuple passes"
      (is (nil? (validator.validate [:map [:dim grammar.measurement]] {:dim [72 :pt]}))))
    (testing ":in tuple passes"
      (is (nil? (validator.validate [:map [:dim grammar.measurement]] {:dim [1 :in]}))))
    (testing ":pc tuple passes"
      (is (nil? (validator.validate [:map [:dim grammar.measurement]] {:dim [18 :pc]})))))
  (testing "invalid"
    (testing "wrong unit keyword"
      (let [result (validator.validate [:map [:dim grammar.measurement]] {:dim [10 :mm]})]
        (is (= :error result.level))))
    (testing "non-number value"
      (let [result (validator.validate [:map [:dim grammar.measurement]] {:dim ["bad" :in]})]
        (is (= :error result.level))))
    (testing "non-table"
      (let [result (validator.validate [:map [:dim grammar.measurement]] {:dim :in})]
        (is (= :error result.level))))))

(run-tests)
