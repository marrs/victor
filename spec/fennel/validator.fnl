(import-macros {: deftest : is : run-tests : testing} :src.fennel.test)
(local validator (require :src.fennel.validator))
(local {: nil? : number?} (require :src.fennel.core))

(deftest validator.validate
  (testing "valid value against a map schema returns nil"
    (is (nil? (validator.validate [:map [:x number?] [:y number?]] {:x 1 :y 2}))))

  (testing "missing required key returns error map"
    (let [result (validator.validate [:map [:x number?] [:y number?]] {:x 1})]
      (is (= :error result.level))
      (is (= :validator/missing-key result.type))
      (is (= "missing required key: :y" result.msg))))

  (testing "wrong type for a key returns error map"
    (let [result (validator.validate [:map [:x number?]] {:x "bad"})]
      (is (= :error result.level))
      (is (= :validator/wrong-type result.type))
      (is (= "wrong type for key: :x" result.msg))))

  (testing "unknown key in value returns warning map"
    (let [result (validator.validate [:map [:x number?]] {:x 1 :z 99})]
      (is (= :warning result.level))
      (is (= :validator/unknown-key result.type))
      (is (= "unknown key: :z" result.msg))))

  (testing "optional key absent returns nil"
    (is (nil? (validator.validate [:map [:x number?] [:y {:optional true} number?]] {:x 1}))))

  (testing "optional key present with correct type returns nil"
    (is (nil? (validator.validate [:map [:x number?] [:y {:optional true} number?]] {:x 1 :y 2}))))

  (testing "optional key present with wrong type returns error map"
    (let [result (validator.validate [:map [:x number?] [:y {:optional true} number?]] {:x 1 :y "bad"})]
      (is (= :error result.level))
      (is (= :validator/wrong-type result.type))
      (is (= "wrong type for key: :y" result.msg)))))

(run-tests)
