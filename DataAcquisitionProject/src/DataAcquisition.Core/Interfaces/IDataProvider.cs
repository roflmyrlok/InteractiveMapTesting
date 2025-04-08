using System.Threading.Tasks;

namespace DataAcquisition.Core.Interfaces
{
	public interface IDataProvider<T>
	{
		Task<T> GetDataAsync(string source);
	}
}