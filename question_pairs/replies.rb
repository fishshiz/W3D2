require_relative 'questions_database'
require_relative 'questions'
class Replies
  attr_accessor :body
  attr_reader :id, :author_id, :question_id, :parent_reply_id


  def initialize(options)
    @id = options['id']
    @author_id = options['author_id']
    @question_id = options['question_id']
    @body = options['body']
    @parent_reply_id = options['parent_reply_id']
  end

  def self.all
    users = QuestionsDatabase.instance.execute("SELECT * FROM replies;")
    users.map{|data| Replies.new(data)}
  end

  def self.find_by_id(id)
    result = QuestionsDatabase.instance.execute("SELECT * FROM replies WHERE id = #{id}")
    result.map { |datum| Replies.new(datum) }
  end

  def self.find_by_user(fname)
    result = QuestionsDatabase.instance.execute("SELECT * FROM replies WHERE author_id = (SELECT id FROM users WHERE fname='#{fname}')")
    result.map { |datum| Replies.new(datum) }
  end

  def self.find_by_question_id(question_id)
    result = QuestionsDatabase.instance.execute("SELECT * FROM replies WHERE question_id = #{question_id}")
    result.map { |datum| Replies.new(datum) }
  end

  def question
    result = QuestionsDatabase.instance.execute("SELECT * FROM questions WHERE id = #{@question_id}")
    result.map { |datum| Questions.new(datum) }
  end

  def parent_reply
    result = QuestionsDatabase.instance.execute("SELECT * FROM replies WHERE id = #{@parent_reply_id}")
    result.map { |datum| Replies.new(datum) }
  end

  def child_replies
    result = QuestionsDatabase.instance.execute("SELECT * FROM replies WHERE parent_reply_id = #{@id}")
    result.map { |datum| Replies.new(datum) }
  end

  def author
    Users.find_by_id(@author_id)
  end

  def create
    raise "Already in database" if @id
    QuestionsDatabase.instance.execute(<<-SQL, @author_id, @question_id, @body, @parent_reply_id, )
      INSERT INTO
       replies (author_id, question_id, body, parent_reply_id)
      VALUES
        (?, ?, ?, ?)
    SQL
    @id =  QuestionsDatabase.instance.last_insert_row_id
  end

  def remove
    raise "Not in database" unless @id
    QuestionsDatabase.instance.execute(<<-SQL, @id)
    DELETE FROM
     replies
    WHERE
      id = ?
    SQL
    @id=nil
  end
end
