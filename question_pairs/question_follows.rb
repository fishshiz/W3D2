require_relative 'questions_database'
require_relative 'questions'
class QuestionFollows
  attr_reader :id, :user_id, :question_id


  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end

  def self.all
    users = QuestionsDatabase.instance.execute("SELECT * FROM question_follows;")
    users.map{|data| QuestionFollows.new(data)}
  end

  def self.find_by_id(id)
    result = QuestionsDatabase.instance.execute("SELECT * FROM question_follows WHERE id = #{id}")
    result.map { |datum| QuestionFollows.new(datum) }
  end

  def self.find_by_user(fname)
    result = QuestionsDatabase.instance.execute("SELECT * FROM question_follows WHERE user_id = (SELECT id FROM users WHERE fname='#{fname}')")
    result.map { |datum| QuestionFollows.new(datum) }
  end

  def create
    raise "Already in database" if @id
    QuestionsDatabase.instance.execute(<<-SQL, @user_id, @question_id)
      INSERT INTO
        question_follows (user_id, question_id)
      VALUES
        (?, ?)
    SQL
    @id =  QuestionsDatabase.instance.last_insert_row_id
  end

  def self.followers_for_question(question_id)
    result = QuestionsDatabase.instance.execute(<<-SQL)
    SELECT
      users.id, users.fname, users.lname
    FROM
      users
    JOIN
      question_follows ON question_follows.user_id = users.id
    WHERE
      question_id = #{question_id}
    SQL
    result.map { |datum| Users.new(datum) }
  end

  def self.most_followed_questions(n)
    result = QuestionsDatabase.instance.execute(<<-SQL)
      SELECT
        questions.id, questions.body, questions.title, questions.author_id
      FROM
        questions
      JOIN
        question_follows ON question_follows.question_id = questions.id
      GROUP BY
        questions.id
      ORDER BY
        COUNT(question_follows.user_id) DESC
      LIMIT
        #{n}
    SQL
    result.map{|datum| Questions.new(datum)}
  end

  def self.followed_questions_for_user_id(user_id)
    result = QuestionsDatabase.instance.execute(<<-SQL)
    SELECT
      questions.id, questions.title, questions.author_id, questions.body
    FROM
      question_follows
    JOIN
      questions ON questions.id = question_follows.question_id
    JOIN
      users ON users.id=question_follows.user_id
    WHERE
      user_id=#{user_id}
    SQL
    result.map { |datum| Questions.new(datum) }
  end



end
