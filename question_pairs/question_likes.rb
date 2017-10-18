require_relative 'questions_database'
require 'byebug'
require_relative 'users'
require_relative 'questions'
class Questionlikes
  attr_reader :id, :user_id, :question_id


  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end

  def self.all
    users = QuestionsDatabase.instance.execute("SELECT * FROM question_likes;")
    users.map{|data| Questionlikes.new(data)}
  end

  def self.find_by_id(id)
    result = QuestionsDatabase.instance.execute("SELECT * FROM question_likes WHERE id = #{id}")
    result.map { |datum| Questionlikes.new(datum) }
  end

  def self.find_by_user(fname)
    result = QuestionsDatabase.instance.execute("SELECT * FROM question_likes WHERE user_id = (SELECT id FROM users WHERE fname='#{fname}')")
    result.map { |datum| Questionlikes.new(datum) }
  end

  def self.num_likes_for_question_id(question_id)
    result = QuestionsDatabase.instance.execute(<<-SQL)
    SELECT
      COUNT(question_likes.id)
    FROM
      question_likes
    JOIN questions
      ON question_likes.question_id = questions.id
    WHERE
      questions.id = #{question_id}
    SQL
    result[0]
  end

  def self.most_liked_questions(n)
    data = QuestionsDatabase.instance.execute(<<-SQL)
    SELECT
      questions.title, questions.body, questions.author_id, questions.id, COUNT(question_likes.question_id)
    FROM
      questions
    LEFT OUTER JOIN question_likes
      ON question_likes.question_id = questions.id
    GROUP BY
      questions.id
    ORDER BY
      COUNT(question_likes.id) DESC
    LIMIT
      #{n}
    SQL

    data.map { |datum| Questions.new(datum) }
  end

  def self.likers_for_question_id(question_id)
    result = QuestionsDatabase.instance.execute(<<-SQL)
    SELECT
      users.id, users.fname, users.lname
    FROM
      users
    JOIN
      question_likes ON question_likes.user_id = users.id
    WHERE
      question_id = #{question_id}
    SQL
    result.map { |datum| Users.new(datum) }
  end

  def self.liked_questions_for_user_id(user_id)
    result = QuestionsDatabase.instance.execute(<<-SQL)
    SELECT
      questions.id, questions.title, questions.author_id, questions.body
    FROM
      question_likes
    JOIN
      questions ON questions.id = question_likes.question_id
    JOIN
      users ON users.id=question_likes.user_id
    WHERE
      user_id=#{user_id}
    SQL
    result.map { |datum| Questions.new(datum) }
  end

  def create
    raise "Already in database" if @id
    QuestionsDatabase.instance.execute(<<-SQL, @user_id, @question_id)
      INSERT INTO
        question_likes (user_id, question_id)
      VALUES
        (?, ?)
    SQL
    @id =  QuestionsDatabase.instance.last_insert_row_id
  end

  def remove
    raise "Not in database" unless @id
    QuestionsDatabase.instance.execute(<<-SQL, @id)
    DELETE FROM
      question_likes
    WHERE
      id = ?
    SQL
    @id=nil
  end



end
