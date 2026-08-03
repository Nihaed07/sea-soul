import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { X, Upload } from 'lucide-react';
import toast from 'react-hot-toast';
import api from '../../services/api';

export default function PackageForm() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [categories, setCategories] = useState([]);
  const [loadingCategories, setLoadingCategories] = useState(true);
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    price: '',
    category: '',
    location: '',
    duration: '',
    isFeatured: false,
    isTrending: false,
    images: [],
  });

  const isEdit = !!id;

  const CLOUDINARY_CLOUD_NAME = 'eeua8tfb';
  const CLOUDINARY_UPLOAD_PRESET = 'seasoul_products';

  useEffect(() => {
    fetchCategories();
    if (isEdit) {
      fetchPackage();
    }
  }, [id]);

  const fetchCategories = async () => {
    try {
      const response = await api.get('/categories');
      const activeCategories = response.data.categories?.filter(cat => cat.isActive !== false) || [];
      setCategories(activeCategories);
    } catch (error) {
      console.error('Error fetching categories:', error);
      toast.error('Failed to load categories');
    } finally {
      setLoadingCategories(false);
    }
  };

  const fetchPackage = async () => {
    try {
      const response = await api.get(`/admin/products/${id}`);
      const product = response.data.product;
      setFormData({
        name: product.name || '',
        description: product.description || '',
        price: product.price || '',
        category: product.category || '',
        location: product.location || '',
        duration: product.duration || '',
        isFeatured: product.isFeatured || false,
        isTrending: product.isTrending || false,
        images: product.images || [],
      });
    } catch (error) {
      console.error('Error fetching package:', error);
      toast.error('Failed to load package data');
    }
  };

  const compressImage = (file) => {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.readAsDataURL(file);
      reader.onload = (event) => {
        const img = new Image();
        img.src = event.target.result;
        img.onload = () => {
          const canvas = document.createElement('canvas');
          let width = img.width;
          let height = img.height;
          const maxDimension = 800;
          if (width > height && width > maxDimension) {
            height = (height / width) * maxDimension;
            width = maxDimension;
          } else if (height > maxDimension) {
            width = (width / height) * maxDimension;
            height = maxDimension;
          }
          canvas.width = width;
          canvas.height = height;
          const ctx = canvas.getContext('2d');
          ctx.imageSmoothingEnabled = true;
          ctx.imageSmoothingQuality = 'high';
          ctx.drawImage(img, 0, 0, width, height);
          const compressedDataUrl = canvas.toDataURL('image/jpeg', 0.7);
          resolve(compressedDataUrl);
        };
        img.onerror = reject;
      };
      reader.onerror = reject;
    });
  };

  const uploadToCloudinary = async (file) => {
    try {
      let compressedBase64;
      if (file.size > 300 * 1024) {
        compressedBase64 = await compressImage(file);
      } else {
        const reader = new FileReader();
        compressedBase64 = await new Promise((resolve, reject) => {
          reader.onload = () => resolve(reader.result);
          reader.onerror = reject;
          reader.readAsDataURL(file);
        });
      }
      const base64Data = compressedBase64.split(',')[1];
      const formData = new FormData();
      formData.append('file', `data:image/jpeg;base64,${base64Data}`);
      formData.append('upload_preset', CLOUDINARY_UPLOAD_PRESET);
      formData.append('folder', 'seasoul/products');
      const response = await fetch(
        `https://api.cloudinary.com/v1_1/${CLOUDINARY_CLOUD_NAME}/image/upload`,
        { method: 'POST', body: formData }
      );
      const data = await response.json();
      if (data.secure_url) {
        return data.secure_url;
      } else {
        throw new Error(data.error?.message || 'Upload failed');
      }
    } catch (error) {
      console.error('❌ Cloudinary upload error:', error);
      throw error;
    }
  };

  const handleImageUpload = async (e) => {
    const files = Array.from(e.target.files);
    if (files.length === 0) return;
    setUploading(true);
    setUploadProgress(0);
    const toastId = toast.loading('Uploading images...');
    const uploadedImages = [];
    let completed = 0;
    for (const file of files) {
      try {
        if (!file.type.startsWith('image/')) {
          toast.error(`File ${file.name} is not an image`);
          continue;
        }
        const url = await uploadToCloudinary(file);
        uploadedImages.push(url);
        completed++;
        setUploadProgress((completed / files.length) * 100);
      } catch (error) {
        console.error('Error uploading image:', error);
        toast.error(`Failed to upload ${file.name}: ${error.message}`);
      }
    }
    setFormData((prev) => ({
      ...prev,
      images: [...prev.images, ...uploadedImages],
    }));
    setUploading(false);
    setUploadProgress(0);
    e.target.value = '';
    if (uploadedImages.length > 0) {
      toast.success(`${uploadedImages.length} image(s) uploaded successfully!`, { id: toastId });
    } else {
      toast.error('No images were uploaded', { id: toastId });
    }
  };

  const removeImage = (index) => {
    setFormData((prev) => ({
      ...prev,
      images: prev.images.filter((_, i) => i !== index),
    }));
    toast.success('Image removed');
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    const toastId = toast.loading(isEdit ? 'Updating package...' : 'Creating package...');
    try {
      const data = {
        ...formData,
        price: parseFloat(formData.price),
      };
      if (isEdit) {
        await api.put(`/admin/products/${id}`, data);
        toast.success('Package updated successfully! 🎉', { id: toastId, duration: 3000 });
      } else {
        await api.post('/admin/products', data);
        toast.success('Package created successfully! 🎉', { id: toastId, duration: 3000 });
      }
      navigate('/packages');
    } catch (error) {
      toast.error(error.response?.data?.message || 'Failed to save package', { id: toastId, duration: 4000 });
    } finally {
      setLoading(false);
    }
  };

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData({
      ...formData,
      [name]: type === 'checkbox' ? checked : value,
    });
  };

  return (
    <div className="max-w-4xl mx-auto px-4 sm:px-0">
      <h1 className="text-2xl font-bold text-gray-800 mb-6">
        {isEdit ? 'Edit Package' : 'Add Package'}
      </h1>
      <form onSubmit={handleSubmit} className="bg-white rounded-xl shadow-sm p-4 sm:p-6">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Package Name *</label>
              <input
                type="text"
                name="name"
                value={formData.name}
                onChange={handleChange}
                className="w-full px-4 py-2 border border-gray-300 rounded-xl focus:ring-2 focus:ring-[#00E5FF] focus:border-[#00E5FF]"
                required
                placeholder="e.g., Luxury Beach Resort"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Description *</label>
              <textarea
                name="description"
                value={formData.description}
                onChange={handleChange}
                rows="4"
                className="w-full px-4 py-2 border border-gray-300 rounded-xl focus:ring-2 focus:ring-[#00E5FF] focus:border-[#00E5FF]"
                required
                placeholder="Describe your package in detail..."
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Price per Day (₹) *</label>
                <input
                  type="number"
                  name="price"
                  value={formData.price}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-xl focus:ring-2 focus:ring-[#00E5FF] focus:border-[#00E5FF]"
                  required
                  placeholder="e.g. 5000"
                />
                <p className="text-xs text-gray-400 mt-1">
                  This price will be multiplied by the number of days selected by the customer.
                </p>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Category *</label>
                <select
                  name="category"
                  value={formData.category}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-xl focus:ring-2 focus:ring-[#00E5FF] focus:border-[#00E5FF]"
                  required
                  disabled={loadingCategories}
                >
                  <option value="">{loadingCategories ? 'Loading...' : 'Select Category'}</option>
                  {categories.map((cat) => (
                    <option key={cat._id} value={cat.name}>
                      {cat.name}
                    </option>
                  ))}
                </select>
                <p className="text-xs text-gray-400 mt-1">
                  Categories can be managed from the <span className="text-[#00E5FF]">Categories</span> section
                </p>
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Location *</label>
              <input
                type="text"
                name="location"
                value={formData.location}
                onChange={handleChange}
                className="w-full px-4 py-2 border border-gray-300 rounded-xl focus:ring-2 focus:ring-[#00E5FF] focus:border-[#00E5FF]"
                required
                placeholder="e.g., Agatti Island"
              />
            </div>
            <div className="flex flex-wrap gap-6">
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  name="isFeatured"
                  checked={formData.isFeatured}
                  onChange={handleChange}
                  className="w-4 h-4 text-[#00E5FF]"
                />
                <span className="text-sm text-gray-700">Featured</span>
              </label>
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  name="isTrending"
                  checked={formData.isTrending}
                  onChange={handleChange}
                  className="w-4 h-4 text-[#00E5FF]"
                />
                <span className="text-sm text-gray-700">Trending</span>
              </label>
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Package Images</label>
            <div className="border-2 border-dashed border-gray-300 rounded-xl p-4 hover:border-[#00E5FF] transition">
              <label className="block cursor-pointer">
                <div className="flex flex-col items-center justify-center py-4">
                  <Upload className="w-8 h-8 text-gray-400 mb-2" />
                  <p className="text-sm text-gray-600 text-center">Click to upload images</p>
                  <p className="text-xs text-gray-400 mt-1 text-center">
                    PNG, JPG, JPEG, WEBP (Max 10MB each, will be compressed)
                  </p>
                </div>
                <input
                  type="file"
                  multiple
                  accept="image/*"
                  onChange={handleImageUpload}
                  className="hidden"
                  disabled={uploading}
                />
              </label>
              {uploading && (
                <div className="text-center text-sm text-[#00E5FF] py-2">
                  Uploading... {uploadProgress > 0 ? `${Math.round(uploadProgress)}%` : ''}
                </div>
              )}
            </div>
            {formData.images.length > 0 && (
              <div className="mt-4">
                <p className="text-sm font-medium text-gray-700 mb-2">
                  Uploaded Images ({formData.images.length})
                </p>
                <div className="grid grid-cols-3 gap-2">
                  {formData.images.map((image, index) => (
                    <div key={index} className="relative group">
                      <img
                        src={image}
                        alt={`Package ${index + 1}`}
                        className="w-full h-24 object-cover rounded-lg border border-gray-200"
                        onError={(e) => {
                          e.target.src = 'https://via.placeholder.com/100x100?text=Error';
                        }}
                      />
                      <button
                        type="button"
                        onClick={() => removeImage(index)}
                        className="absolute -top-2 -right-2 bg-red-500 text-white rounded-full p-1 opacity-0 group-hover:opacity-100 transition"
                      >
                        <X size={14} />
                      </button>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
        <div className="flex flex-col sm:flex-row gap-4 pt-6 border-t border-gray-200 mt-6">
          <button
            type="submit"
            disabled={loading || uploading}
            className="px-6 py-2 bg-[#00E5FF] text-[#0D1516] font-bold rounded-xl hover:opacity-90 disabled:opacity-50 w-full sm:w-auto"
          >
            {loading ? 'Saving...' : isEdit ? 'Update Package' : 'Create Package'}
          </button>
          <button
            type="button"
            onClick={() => navigate('/packages')}
            className="px-6 py-2 bg-gray-200 text-gray-700 font-bold rounded-xl hover:bg-gray-300 w-full sm:w-auto"
          >
            Cancel
          </button>
        </div>
      </form>
    </div>
  );
}