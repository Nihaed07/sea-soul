import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { Plus, Edit, Trash2, Package as PackageIcon, Image as ImageIcon, Search } from 'lucide-react';
import toast from 'react-hot-toast';
import api from '../../services/api';

export default function PackagesList() {
  const [packages, setPackages] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [searchTerm, setSearchTerm] = useState('');
  const [deleteConfirm, setDeleteConfirm] = useState(null);

  // ✅ All 5 categories
  const categories = ['All', 'Resorts', 'Activities', 'Scuba', 'Honeymoon', 'Dining'];

  useEffect(() => {
    fetchPackages();
  }, []);

  const fetchPackages = async () => {
    try {
      const response = await api.get('/admin/products');
      setPackages(response.data.products || []);
    } catch (error) {
      console.error('Error fetching packages:', error);
      toast.error('Failed to load packages');
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id) => {
    setDeleteConfirm(id);
  };

  const confirmDelete = async () => {
    const id = deleteConfirm;
    setDeleteConfirm(null);
    const toastId = toast.loading('Deleting package...');

    try {
      await api.delete(`/admin/products/${id}`);
      toast.success('Package deleted successfully! 🗑️', {
        id: toastId,
        duration: 3000,
      });
      fetchPackages();
    } catch (error) {
      toast.error(error.response?.data?.message || 'Failed to delete package', {
        id: toastId,
        duration: 4000,
      });
    }
  };

  const getCategoryColor = (category) => {
    const colors = {
      'Resorts': 'bg-blue-100 text-blue-700',
      'Activities': 'bg-green-100 text-green-700',
      'Scuba': 'bg-cyan-100 text-cyan-700',
      'Honeymoon': 'bg-pink-100 text-pink-700',
      'Dining': 'bg-orange-100 text-orange-700',
    };
    return colors[category] || 'bg-gray-100 text-gray-700';
  };

  const filteredPackages = packages.filter(pkg => {
    const matchCategory = selectedCategory === 'all' || pkg.category === selectedCategory;
    const matchSearch = pkg.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                        pkg.location?.toLowerCase().includes(searchTerm.toLowerCase());
    return matchCategory && matchSearch;
  });

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#00E5FF] mx-auto"></div>
          <p className="mt-4 text-gray-600">Loading packages...</p>
        </div>
      </div>
    );
  }

  return (
    <div>
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6">
        <div>
          <h1 className="text-2xl font-bold text-[#1A2B49]">Packages</h1>
          <p className="text-sm text-gray-500 mt-1">Manage all tour packages</p>
        </div>
        <Link
          to="/packages/add"
          className="flex items-center justify-center gap-2 px-4 py-2.5 bg-[#00E5FF] text-[#1A2B49] font-semibold rounded-xl hover:bg-[#00E5FF]/80 transition shadow-sm"
        >
          <Plus size={18} />
          Add Package
        </Link>
      </div>

      {/* Search & Filter */}
      <div className="flex flex-col sm:flex-row gap-4 mb-6">
        <div className="relative flex-1">
          <Search size={18} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            placeholder="Search packages by name or location..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-4 py-2.5 bg-white border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#00E5FF] focus:border-transparent"
          />
        </div>
        <div className="flex flex-wrap gap-2">
          {categories.map((category) => (
            <button
              key={category}
              onClick={() => setSelectedCategory(category)}
              className={`px-3 sm:px-4 py-2 rounded-xl text-xs sm:text-sm font-medium transition whitespace-nowrap ${
                selectedCategory === category
                  ? 'bg-[#1A2B49] text-white'
                  : 'bg-white text-gray-600 hover:bg-gray-100 border border-gray-200'
              }`}
            >
              {category}
            </button>
          ))}
        </div>
      </div>

      {/* Packages Grid */}
      {filteredPackages.length === 0 ? (
        <div className="bg-white rounded-2xl shadow-sm p-8 md:p-12 text-center border border-gray-100">
          <div className="flex flex-col items-center">
            <PackageIcon size={48} className="text-gray-300 mb-4" />
            <h3 className="text-lg font-medium text-[#1A2B49]">No packages found</h3>
            <p className="text-gray-500 text-sm mt-1">
              {searchTerm || selectedCategory !== 'all' 
                ? 'Try adjusting your search or filter' 
                : 'Add your first package to get started'}
            </p>
            {(searchTerm || selectedCategory !== 'all') ? (
              <button
                onClick={() => { setSearchTerm(''); setSelectedCategory('all'); }}
                className="mt-4 text-[#00E5FF] font-medium hover:underline"
              >
                Clear filters
              </button>
            ) : (
              <Link
                to="/packages/add"
                className="mt-4 inline-flex items-center gap-2 px-4 py-2 bg-[#00E5FF] text-[#1A2B49] font-semibold rounded-xl hover:bg-[#00E5FF]/80 transition"
              >
                <Plus size={18} />
                Add Package
              </Link>
            )}
          </div>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-4 md:gap-6">
          {filteredPackages.map((pkg) => (
            <div
              key={pkg._id}
              className="bg-white rounded-2xl border border-gray-100 overflow-hidden hover:shadow-lg transition-all duration-300 hover:-translate-y-1"
            >
              <div className="relative h-48 sm:h-52 bg-gray-100">
                {pkg.images && pkg.images.length > 0 ? (
                  <img
                    src={pkg.images[0]}
                    alt={pkg.name}
                    className="w-full h-full object-cover"
                    onError={(e) => {
                      e.target.src = 'https://via.placeholder.com/400x300?text=No+Image';
                    }}
                  />
                ) : (
                  <div className="flex items-center justify-center h-full bg-gray-50">
                    <ImageIcon size={48} className="text-gray-300" />
                  </div>
                )}
                <div className="absolute top-3 left-3 flex flex-wrap gap-2">
                  {pkg.isFeatured && (
                    <span className="px-2.5 py-1 bg-yellow-400 text-yellow-900 text-xs font-bold rounded-full">
                      FEATURED
                    </span>
                  )}
                  {pkg.isTrending && (
                    <span className="px-2.5 py-1 bg-red-400 text-red-900 text-xs font-bold rounded-full">
                      TRENDING
                    </span>
                  )}
                </div>
              </div>

              <div className="p-4 md:p-5">
                <div className="flex items-start justify-between gap-2">
                  <div className="flex-1 min-w-0">
                    <h3 className="font-semibold text-[#1A2B49] truncate">
                      {pkg.name}
                    </h3>
                    <p className="text-sm text-gray-500 truncate">
                      📍 {pkg.location || 'Location not specified'}
                    </p>
                  </div>
                  <span className={`px-2.5 py-1 rounded-full text-xs font-medium whitespace-nowrap ${getCategoryColor(pkg.category)}`}>
                    {pkg.category}
                  </span>
                </div>

                <div className="mt-3 flex items-center gap-2 flex-wrap">
                  <span className="text-xl font-bold text-[#00E5FF]">
                    ₹{pkg.price} / Day
                  </span>
                </div>

                <div className="mt-4 flex items-center gap-2 pt-3 border-t border-gray-100">
                  <Link
                    to={`/packages/edit/${pkg._id}`}
                    className="flex-1 flex items-center justify-center gap-1.5 px-3 py-2 text-blue-600 hover:bg-blue-50 rounded-lg text-sm font-medium transition"
                  >
                    <Edit size={15} />
                    Edit
                  </Link>
                  <button
                    onClick={() => handleDelete(pkg._id)}
                    className="flex-1 flex items-center justify-center gap-1.5 px-3 py-2 text-red-600 hover:bg-red-50 rounded-lg text-sm font-medium transition"
                  >
                    <Trash2 size={15} />
                    Delete
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Delete Confirmation Modal */}
      {deleteConfirm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl">
            <div className="text-center">
              <div className="w-16 h-16 bg-red-50 rounded-full flex items-center justify-center mx-auto mb-4">
                <Trash2 size={28} className="text-red-500" />
              </div>
              <h3 className="text-xl font-bold text-[#1A2B49] mb-2">Delete Package?</h3>
              <p className="text-gray-500 text-sm mb-6">
                Are you sure you want to delete this package? This action cannot be undone.
              </p>
              <div className="flex flex-col sm:flex-row gap-3">
                <button
                  onClick={() => setDeleteConfirm(null)}
                  className="flex-1 px-4 py-2.5 bg-gray-100 text-gray-700 font-medium rounded-xl hover:bg-gray-200 transition"
                >
                  Cancel
                </button>
                <button
                  onClick={confirmDelete}
                  className="flex-1 px-4 py-2.5 bg-red-500 text-white font-medium rounded-xl hover:bg-red-600 transition"
                >
                  Delete
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}