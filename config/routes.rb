Webapp::Application.routes.draw do
  get "street_map/one_factor"
  get "street_map/two_factor"

  get "parallel/boroughs"
  get "parallel/wards"
  get "parallel/devices"
  get "parallel/hashtags"

  get "matrix/hashtag"
  get "matrix/area"
  get "matrix/device"
  get "matrix/aggr_hashtag"
  get "matrix/aggr_device"
  get "matrix/aggr_area"

  get "donut/boro_devices"

  get "rawdata/area_factors"
  get "rawdata/device_factors"
  get "rawdata/hashtag_factors"
  get "rawdata/area_sentiment"
  get "rawdata/hashtag_sentiment"
  get "rawdata/device_sentiment"
  get "rawdata/area_assoc"
  get "rawdata/hashtag_assoc"
  get "rawdata/device_assoc"

  get "summary/area"


  get "bubble/hashtag"
  get "bubble/device"
  get "bubble/area"

  get 'application/intro'

  #Parameter routes
  get "street_map/two_factor/:factor_one/:factor_two" => "street_map#two_factor"


  #Default routes
  get "donut" => "donut#boro_devices"
  get "bubble" => "bubble#hashtag"
  get "street_map" => "street_map#one_factor"
  get "parallel" => "parallel#boroughs"
  get "matrix" => "matrix#hashtag"
  get "rawdata" => "rawdata#area_factors"
  get "summary" => "summary#area"
  
  root 'application#intro'
  
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end
  
  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
