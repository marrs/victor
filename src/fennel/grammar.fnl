(local {: number? : string? : table?} (require :src.fennel.core))

(local measurement [:or number? [:tuple number? [:enum :in :pt :pc]]])

(local bic
  [:map
   [:width  {:error-type :grammar/measurement} measurement]
   [:height {:error-type :grammar/measurement} measurement]])

(local rect
  [:map
   [:x            measurement]
   [:y            measurement]
   [:width        measurement]
   [:height       measurement]
   [:rx           {:optional true} measurement]
   [:ry           {:optional true} measurement]
   [:fill         {:optional true} string?]
   [:stroke       {:optional true} string?]
   [:stroke-width {:optional true} measurement]])

(local circle
  [:map
   [:cx           measurement]
   [:cy           measurement]
   [:r            measurement]
   [:fill         {:optional true} string?]
   [:stroke       {:optional true} string?]
   [:stroke-width {:optional true} measurement]])

(local text
  [:map
   [:x    measurement]
   [:y    measurement]
   [:font string?]
   [:size measurement]
   [:str  string?]])

(local path
  [:map
   [:x            measurement]
   [:y            measurement]
   [:fill         {:optional true} string?]
   [:stroke       {:optional true} string?]
   [:stroke-width {:optional true} measurement]
   [:stroke-cap   {:optional true} string?]])

{: measurement : bic : rect : circle : text : path}
