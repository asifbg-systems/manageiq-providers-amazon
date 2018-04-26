module ManageIQ::Providers::Amazon::Inventory::Persister::Shared::CloudCollections
  extend ActiveSupport::Concern

  included do
    # Builder class for Cloud
    def cloud
      ::ManagerRefresh::InventoryCollection::Builder::CloudManager
    end

    def add_miq_templates(extra_properties = {})
      add_collection(cloud, :miq_templates, extra_properties) do |builder|
        builder.add_properties(:model_class => ::ManageIQ::Providers::Amazon::CloudManager::Template)
        builder.add_builder_params(:template => true)
      end
    end

    def add_flavors(extra_properties = {})
      add_collection(cloud, :flavors, extra_properties)
    end

    def add_vm_and_template_labels
      add_collection(cloud, :vm_and_template_labels) do |builder|
        builder.add_targeted_arel(
          lambda do |inventory_collection|
            manager_uuids = inventory_collection.parent_inventory_collections.collect(&:manager_uuids).map(&:to_a).flatten
            inventory_collection.parent.vm_and_template_labels.where(
              'vms' => {:ems_ref => manager_uuids}
            )
          end
        )
      end
    end

    def add_vm_and_template_taggings
      add_collection(cloud, :vm_and_template_taggings) do |builder|
        builder.add_properties(
          :model_class                  => Tagging,
          :manager_ref                  => %i(taggable tag),
          :parent_inventory_collections => %i(vms miq_templates)
        )

        builder.add_targeted_arel(
          lambda do |inventory_collection|
            manager_uuids = inventory_collection.parent_inventory_collections.collect(&:manager_uuids).map(&:to_a).flatten
            ems = inventory_collection.parent
            ems.vm_and_template_taggings.where(
              'taggable_id' => ems.vms_and_templates.where(:ems_ref => manager_uuids)
            )
          end
        )
      end
    end

    def add_key_pairs(extra_properties = {})
      add_collection(cloud, :key_pairs, extra_properties) do |builder|
        builder.add_properties(:model_class => ::ManageIQ::Providers::Amazon::CloudManager::AuthKeyPair)
      end
    end

    def add_orchestration_stacks(extra_properties = {})
      add_collection(cloud, :orchestration_stacks, extra_properties) do |builder|
        builder.add_properties(:model_class => ::ManageIQ::Providers::Amazon::CloudManager::OrchestrationStack)
      end
    end

    def add_vm_and_miq_template_ancestry
      add_collection(cloud, :vm_and_miq_template_ancestry, {}, {:auto_object_attributes => false, :auto_model_class => false, :without_model_class => true}) do |builder|
        builder.add_dependency_attributes(
          :vms           => [collections[:vms]],
          :miq_templates => [collections[:miq_templates]]
        )
      end
    end

    def add_orchestration_stack_ancestry
      add_collection(cloud, :orchestration_stack_ancestry, {}, {:auto_object_attributes => false, :auto_model_class => false, :without_model_class => true}) do |builder|
        builder.add_dependency_attributes(
          :orchestration_stacks           => [collections[:orchestration_stacks]],
          :orchestration_stacks_resources => [collections[:orchestration_stacks_resources]]
        )
      end
    end
  end
end
