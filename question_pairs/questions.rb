require_relative 'questions_database'
require_relative 'users'
require 'byebug'
require_relative 'question_likes'

class Questions
  attr_accessor :title, :body
  attr_reader :id, :author_id

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM questions")
    data.map { |datum| Questions.new(datum) }
  end

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @author_id = options['author_id']
  end

  def self.find_by_id(id)
    result = QuestionsDatabase.instance.execute("SELECT * FROM questions WHERE id = #{id}")
    result.map { |datum| Questions.new(datum) }
  end

  def self.find_by_author_fname(fname)
    result = QuestionsDatabase.instance.execute("SELECT * FROM questions WHERE author_id = (SELECT id FROM users WHERE fname='#{fname}')")
    result.map { |datum| Questions.new(datum) }
  end

  def self.find_by_title(title)
    result = QuestionsDatabase.instance.execute("SELECT * FROM questions WHERE title='#{title}'")
    result.map { |datum| Questions.new(datum) }
  end

  def self.most_liked(n)
    Questionlikes.most_liked_questions(n)
  end

  def author
    Users.find_by_id(@author_id)
  end

  def followers
    QuestionFollows.followers_for_question(@id)
  end

  def replies
    Replies.find_by_question_id(@id)
  end

  def likers
    Questionlikes.likers_for_question_id(@id)
  end

  def num_likes
    Questionlikes.num_likes_for_question_id(@id)
  end

  def create
    raise "Already in database" if @id
    QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @author_id)
      INSERT INTO
        questions (title, body, author_id)
      VALUES
        (?, ?, ?)
    SQL
    @id =  QuestionsDatabase.instance.last_insert_row_id
  end

  def update
    raise "Not in database" if !@id
    QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @author_id, @id)
      UPDATE
        questions
      SET
        title=?, body=?, author_id=?
      WHERE
        id=?
    SQL
  end

end
