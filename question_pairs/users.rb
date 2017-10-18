require_relative 'questions_database'
require_relative 'questions'
require_relative 'replies'
require_relative 'question_follows'

class Users
  attr_accessor :fname, :lname
  attr_reader :id


  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  def self.all
    users = QuestionsDatabase.instance.execute("SELECT * FROM users;")
    users.map{|data| Users.new(data)}
  end

  def self.find_by_fname(fname)
    result = QuestionsDatabase.instance.execute(<<-SQL)
      SELECT
        *
      FROM
        users
      WHERE
        users.fname = ?
      SQL
    result.map { |datum| Users.new(datum) }
  end

  def self.find_by_lname(lname)
    result = QuestionsDatabase.instance.execute("SELECT * FROM users WHERE users.lname = '#{lname}'")
    result.map { |datum| Users.new(datum) }
  end

  def self.find_by_id(id)
    result = QuestionsDatabase.instance.execute("SELECT * FROM users WHERE users.id = #{id}")
    result.map { |datum| Users.new(datum) }
  end

  def authored_questions
    Questions.find_by_author_fname(@fname)
  end

  def authored_replies
    Replies.find_by_user(@fname)
  end

  def followed_questions
    QuestionFollows.followed_questions_for_user_id(@id)
  end

  def create
    raise "Already in database" if @id
    QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname)
      INSERT INTO
        users (fname, lname)
      VALUES
        (?, ?)
    SQL
    @id =  QuestionsDatabase.instance.last_insert_row_id
  end

  def average_karma
    data = QuestionsDatabase.instance.execute(<<-SQL)
      -- SELECT
      --   CAST(COUNT(question_likes.id)/COUNT(DISTINCT questions.id) AS float)
      -- FROM
      --   questions
      -- JOIN
      --   question_likes ON question_likes.question_id = questions.id
      -- WHERE
      --   questions.author_id = #{@id} AND question_likes.user_id = #{@id}

      SELECT
        CAST(COUNT(question_likes.question_id) AS FLOAT) / COUNT(DISTINCT(questions.id))
      FROM
        questions
      LEFT OUTER JOIN question_likes
        ON question_likes.question_id = questions.id
      WHERE
        questions.author_id = #{@id}
    SQL
  end

  def update
    raise "Not in database" if !@id
    QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname, @id)
      UPDATE
        users
      SET
        fname=?, lname=?
      WHERE
        id=?
    SQL
  end

  def liked_questions
    Questionlikes.liked_questions_for_user_id(@id)
  end


end
