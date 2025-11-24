require 'roda'
require 'json'

class App < Roda
  plugin :json
  plugin :render, engine: 'erb', views: 'views'
  plugin :static, ["/css", "/img", "/fonts"]

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

  def create_math_equation(num_vars = 3, complexity = 1)
    # Permited variables
    complexity = complexity.to_i
    complexity = 1 if complexity < 1
    max_val_vars = 10 * complexity
    max_num_vars = 5 * complexity
    num_vars = num_vars.to_i
    num_vars = 3 if num_vars < 3
    num_vars = max_num_vars if num_vars > max_num_vars

    # Permited operators
    ops_available = [:+, :-, :*]

    # N numbers
    values = []
    while values.size < num_vars
      n = rand(1..max_val_vars)
      values << n
    end

    # N-1 random operators
    ops = Array.new(num_vars - 1) { ops_available.sample }

    # Building our equation
    parts = [values.first.to_s]
    ops.each_with_index do |op, idx|
      parts << op.to_s
      parts << values[idx + 1].to_s
    end
    expression = parts.join(" ")

    # Get correct answer
    result = eval(expression)

    # Get wrong answers
    wrong_answers = []
    while wrong_answers.size < 2
      delta = rand(-8..8)
      fake = result + delta
      next if fake == result || wrong_answers.include?(fake)
      wrong_answers << fake
    end

    options = ([result] + wrong_answers).shuffle
    {
      expression: expression,
      correct: result,
      wrongs: wrong_answers,
      options: options
    }
  end

  route do |r|
    # === Landing Page ===
    r.root do
      view("index", layout: false)
    end

    # === API ===
    r.on "api" do
      # === HIGHSCORES ===
      r.on "highscores" do
        # GET /api/highscores → SCORES LIST
        r.get do
          scores = read_scores
          id_param = r.params["id"].to_s.strip

          if !id_param.empty?
            # Search by ID
            wanted_id = id_param.to_i
            scores.select { |s| s["id"].to_i == wanted_id }
          else
            # TOP 10
            scores
              .sort_by { |s| [-s["levels"].to_i, s["time"].to_f] }
              .take(10)
          end
        end
        
        # POST /api/highscores → SAVE SCORES
        r.post do
          raw_data = r.params.empty? ? JSON.parse(r.body.read) : r.params

          puts "📥 RAW HIGHSCORE DATA: #{raw_data.inspect}"

          scores = read_scores

          # NEXT ID
          last_id = scores.map { |s| s["id"].to_i }.max || 0
          next_id = last_id + 1

          new_score = {
            "id"     => next_id,
            "player" => raw_data["player"],
            "levels" => raw_data["levels"].to_i,
            "time"   => raw_data["time"].to_f
          }

          puts "💾 SAVING HIGHSCORE: #{new_score.inspect}"

          scores << new_score
          write_scores(scores)

          { status: "ok", id: next_id, new_score: new_score }
        end
      end

      # === MATH ===
      r.on "math" do
        r.on "random" do
          # GET /api/math/random → GET EQUATION
          r.get do
            create_math_equation(r.params["vars"], r.params["complexity"])
          end
        end
      end

      # === PING ===
      r.on "ping" do
        r.get do
          { ok: true, time: Time.now.to_i }
        end
      end
    end
  end
end
