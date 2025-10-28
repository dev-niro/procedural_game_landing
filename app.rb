require 'roda'
require 'json'

class App < Roda
  plugin :json
  plugin :render, engine: 'erb', views: 'views'
  plugin :static, ["/css", "/img", "/fonts"]  # sirve los archivos desde /public

  # DEV URL = strangely-distinct-longhorn.ngrok-free.app
  SCORES_FILE = "scores.json"

  def read_scores
    return [] unless File.exist?(SCORES_FILE)
    content = File.read(SCORES_FILE).strip
    content.empty? ? [] : JSON.parse(content)
  end

  def write_scores(data)
    File.write(SCORES_FILE, JSON.pretty_generate(data))
  end

  route do |r|
    # === Landing Page ===
    r.root do
      view("index", layout: false)
    end

    # === API ===
    r.on "api" do
      r.on "highscores" do
        # GET /api/highscores → lista de puntajes
        r.get do
          read_scores.sort_by { |s| -s["score"].to_i }.take(10)
        end

        # POST /api/highscores → guarda nuevo puntaje
        r.post do
          data = r.params.empty? ? JSON.parse(r.body.read) : r.params
          scores = read_scores
          scores << { "player" => data["player"], "levels" => data["levels"].to_i, "time" => data["time"].to_f  }
          write_scores(scores)
          { status: "ok" }
        end
      end
    end
  end
end
