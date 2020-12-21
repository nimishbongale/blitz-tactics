# For generating daily speedrun levels

module SpeedrunLevelCreator
  LEVELS_DIR = Rails.root.join("data/levels")

  N_PUZZLES = 30

  V = 70  # min votes to be considered
  A = 100 # min attempts to be considered

  POOL_1 = [
    Puzzle.rating_range(1000, 1310).white_to_move.vote_gt(V).attempts_gt(A),
    Puzzle.rating_range(1311, 1450).black_to_move.vote_gt(V).attempts_gt(A),
    Puzzle.rating_range(1451, 1550).white_to_move.vote_gt(V).attempts_gt(A),
    Puzzle.rating_range(1551, 1650).black_to_move.vote_gt(V).attempts_gt(A),
    Puzzle.rating_range(1651, 1750).white_to_move.vote_gt(V).attempts_gt(A),
  ].map {|pool| pool.new_not_deleted.no_retry }

  POOL_2 = [
    Puzzle.rating_range(1000, 1310).black_to_move.vote_gt(V).attempts_gt(A),
    Puzzle.rating_range(1311, 1450).white_to_move.vote_gt(V).attempts_gt(A),
    Puzzle.rating_range(1451, 1550).black_to_move.vote_gt(V).attempts_gt(A),
    Puzzle.rating_range(1551, 1650).white_to_move.vote_gt(V).attempts_gt(A),
    Puzzle.rating_range(1651, 1750).black_to_move.vote_gt(V).attempts_gt(A),
  ].map {|pool| pool.new_not_deleted.no_retry }

  def count_pools
    ActiveRecord::Base.logger.silence do
      w_pool = POOL_1.map { |pool| pool.count }
      puts "pool 1: #{w_pool} = #{w_pool.sum}"
      b_pool = POOL_2.map { |pool| pool.count }
      puts "pool 2: #{b_pool} = #{b_pool.sum}"
      puts "total #: #{w_pool.sum + b_pool.sum}"
    end
  end

  def export_puzzles_for_date_range(from_date, to_date)
    date_range = Date.strptime(from_date)..Date.strptime(to_date)
    date_range.each do |date|
      puzzles = generate_puzzles(date)
      open("#{LEVELS_DIR}/speedruns/speedrun-#{date.strftime}.json", "w") do |f|
        f.write JSON.pretty_generate(puzzles).to_s
      end
    end
  end

  # seed = used for random numbers
  def puzzle_ids(seed, pool)
    n = N_PUZZLES / pool.size
    puzzle_ids = []
    pool.each do |pool|
      puzzles = pool.shuffle(random: Random.new(seed)).take(n)
      puzzle_ids << puzzles.map(&:id)
    end
    puzzle_ids.flatten
  end

  def generate_puzzles(date)
    pool = date.day % 2 == 0 ? POOL_1 : POOL_2
    if pool == POOL_1
      puts "Using pool 1 for #{date.to_s}"
    elsif pool == POOL_2
      puts "Using pool 2 for #{date.to_s}"
    end
    ActiveRecord::Base.logger.silence do
      ids = puzzle_ids(date.hash, pool)
      ids.map do |id|
        LichessPuzzle.find(id).simplified_data
      end
    end
  end

  extend self
end
