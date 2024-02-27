#!/usr/bin/env bb

(ns bash-pack
  (:require
    [babashka.cli :as cli]
    [babashka.fs :as fs]
    [clojure.string :as str]))

#?(:bb      (do (require '[babashka.deps])
                (babashka.deps/add-deps '{:deps {org.clojure/clojure {:mvn/version "1.11.1"}
                                                 babashka/fs {:mvn/version "0.2.12"}
                                                 org.babashka/cli {:mvn/version "0.8.57"}}}))
   :default (do))

;; ---------- CORE --------------------

(defn process-file
  [{:keys [filename cwd top?] :or {top? true}}]
  (let [path (str (fs/path cwd filename))
        content (-> (slurp path)
                    (str/split-lines))
        content' (if (-> (first content) (str/starts-with? "#!/"))
                   (drop 1 content)
                   content)
        content'' (->> content'
                       (drop-while str/blank?))
        result (->> content''
                    (filter #(not (str/starts-with? % "#!/")))
                    (map (fn [l]
                           (if (str/starts-with? l "source")
                             (let [[_ sourced-file] (str/split l #" ")]
                               (process-file {:filename sourced-file :cwd (fs/parent path) :top? false}))
                             l)))
                    (str/join "\n"))]
    (str (when top? (str (first content) "\n"))
         (str "# source of " path " - BEGIN\n")
         result
         "\n"
         (str "# source of " path " - END\n"))))

(defn process
  [{:keys [entry output]}]
  (let [res (process-file {:filename entry :cwd "."})]
    (fs/create-dirs (fs/parent output))
    (println res)
    (spit output res)
    res))

(comment
  (process-file "../src/scripts/install_asdf.bash"))

;; ---------- MAIN --------------------

(def cli-options {:entry {:coerce :string}
                  :output {:coerce :string}
                  :help {:coerce :boolean}})

(defn -main [& _args]
  (let [opts (cli/parse-opts *command-line-args* {:spec cli-options})]
    (prn opts)
    (process opts)))

(when (= *file* (System/getProperty "babashka.file"))
  (apply -main *command-line-args*))
