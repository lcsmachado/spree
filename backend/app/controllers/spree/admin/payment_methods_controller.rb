module Spree
  module Admin
    class PaymentMethodsController < ResourceController
      skip_before_action :load_resource, only: :create
      before_action :load_data
      before_action :validate_payment_method_provider, only: :create

      respond_to :html

      def create
        @payment_method = params[:payment_method].delete(:type).constantize.new(payment_method_params)
        byebug
        @object = @payment_method
        invoke_callbacks(:create, :before)
        if @payment_method.save
          invoke_callbacks(:create, :after)
          flash[:success] = Spree.t(:successfully_created, resource: Spree.t(:payment_method))
          redirect_to edit_admin_payment_method_path(@payment_method)
        else
          invoke_callbacks(:create, :fails)
          respond_with(@payment_method)
        end
      end

      def update
        invoke_callbacks(:update, :before)
        payment_method_type = params[:payment_method].delete(:type)
        byebug
        if @payment_method['type'].to_s != payment_method_type
          @payment_method.update_columns(
            type: payment_method_type,
            updated_at: Time.current
          )
          @payment_method = PaymentMethod.find(params[:id])
        end

        attributes = payment_method_params.merge(preferences_params)
        attributes.each do |k, _v|
          attributes.delete(k) if k.include?('password') && attributes[k].blank?
        end

        if @payment_method.update(attributes)
          invoke_callbacks(:update, :after)
          flash[:success] = Spree.t(:successfully_updated, resource: Spree.t(:payment_method))
          redirect_to edit_admin_payment_method_path(@payment_method)
        else
          invoke_callbacks(:update, :fails)
          respond_with(@payment_method)
        end
      end

      private

      def collection
        @collection = super.order(position: :asc)
      end

      def load_data
        @stores = Spree::Store.all
        @providers = Gateway.providers.sort_by(&:name)
      end

      def validate_payment_method_provider
        valid_payment_methods = Rails.application.config.spree.payment_methods.map(&:to_s)
        unless valid_payment_methods.include?(params[:payment_method][:type])
          flash[:error] = Spree.t(:invalid_payment_provider)
          redirect_to new_admin_payment_method_path
        end
      end

      def payment_method_params
        params.require(:payment_method).permit!
      end

      def preferences_params
        key = ActiveModel::Naming.param_key(@payment_method)
        return {} unless params.key? key

        params.require(key).permit!
      end
    end
  end
end
