class EntriesController < ApplicationController
  before_action :set_entry, only: %i[ edit update destroy ]

  # GET /entries or /entries.json
  def index
    @today = Time.zone.today
    @entries = Entry.recent
    @today_total_calories = Entry.eaten_on(@today).sum(:calories)
  end

  # GET /entries/new
  def new
    @entry = Entry.new(eaten_at: Time.zone.now)
  end

  # GET /entries/1/edit
  def edit
  end

  # POST /entries or /entries.json
  def create
    @entry = Entry.new(entry_params)

    if @entry.save
      redirect_to entries_path, notice: "記録を追加しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /entries/1 or /entries/1.json
  def update
    if @entry.update(entry_params)
      redirect_to entries_path, notice: "記録を更新しました。", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /entries/1 or /entries/1.json
  def destroy
    @entry.destroy!

    redirect_to entries_path, notice: "記録を削除しました。", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_entry
      @entry = Entry.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def entry_params
      params.expect(entry: [ :name, :calories, :eaten_at, :note ])
    end
end
