;; clojure.test style unit testing library.
;;
;; In test files:
;;   (import-macros {: deftest : is : testing : are : thrown? : run-tests} :src.fennel.test)
;;   (deftest my-test ...)
;;   (run-tests)
;;
;; State is stored in package.loaded[state-key] so it is shared across
;; environment boundaries.  The macro sandbox does not expose `package`, so
;; state is never touched at module load time; it is created lazily by the
;; first (deftest ...) form that executes at runtime.

(local state-key :src.fennel.test/state)

;; Compile-time helper: builds a (do form1 form2 ...) AST node from a sequence of forms.
(fn do-block [forms]
  (let [blk `(do)]
    (each [_ form (ipairs forms)]
      (table.insert blk form))
    blk))

;; Macro functions — returned in the module table so import-macros can find them.
;; Each receives AST nodes as arguments and returns an AST node.

(fn deftest [name & body]
  `(do
     (local fn# (fn [] ,(do-block body)))
     (when (= nil (. package.loaded ,state-key))
       (tset package.loaded ,state-key
         {:list [] :pass 0 :fail 0 :errors [] :current nil :ctx nil}))
     (let [st# (. package.loaded ,state-key)]
       (table.insert st#.list {:name ,(tostring name) :fn fn#}))))

(fn is [form ?msg]
  `(let [st# (. package.loaded ,state-key)]
     (if ,form
       (tset st# :pass (+ st#.pass 1))
       (do
         (tset st# :fail (+ st#.fail 1))
         (table.insert st#.errors
           {:test st#.current
            :ctx  st#.ctx
            :form ,(tostring form)
            :msg  ,?msg})))))

(fn testing [desc & body]
  `(let [st# (. package.loaded ,state-key)
         prev# st#.ctx]
     (tset st# :ctx ,desc)
     ,(do-block body)
     (tset st# :ctx prev#)))

;; Tabular assertions. Bindings and values are interleaved; form is tested for each row.
;; (are [xx yy] (= xx yy)  1 1  2 2  3 3)
(fn are [bindings form & args]
  (let [nb (length bindings)
        result `(do)]
    (var ii 1)
    (while (<= (+ ii (- nb 1)) (length args))
      (let [let-binds `[]]
        (for [jj 0 (- nb 1)]
          (table.insert let-binds (. bindings (+ jj 1)))
          (table.insert let-binds (. args (+ ii jj))))
        (table.insert result `(is (let ,let-binds ,form))))
      (set ii (+ ii nb)))
    result))

(fn thrown? [& body]
  `(let [(ok# _#) (pcall (fn [] ,(do-block body)))]
     (not ok#)))

(fn run-tests []
  `(let [st# (. package.loaded ,state-key)]
     (each [_# test# (ipairs st#.list)]
       (tset st# :current test#.name)
       (tset st# :ctx nil)
       (test#.fn))
     (print (string.format "\n%d passed, %d failed" st#.pass st#.fail))
     (each [_# err# (ipairs st#.errors)]
       (let [where# (.. (or err#.test "?")
                       (if err#.ctx (.. " [" err#.ctx "]") ""))
             what#  (if err#.msg (.. err#.form " — " err#.msg) err#.form)]
         (print (string.format "FAIL in %s: %s" where# what#))))
     (= st#.fail 0)))

{: deftest : is : testing : are : thrown? : run-tests}
