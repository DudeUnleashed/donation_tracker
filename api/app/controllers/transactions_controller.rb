class TransactionsController < ApplicationController
  def create
    # Assuming you're creating a donation transaction
    donation_data = params.require(:donation).permit(:amount, :currency, :platform, :donation_date, :user)

    # Create a new donation record in the database
    donation = Donation.new(donation_data)

    if donation.save
      render json: { message: 'Donation successfully created' }, status: :created
    else
      render json: { error: 'Failed to create donation' }, status: :unprocessable_entity
    end
  end
end
