using System.Collections.Generic;
using System.Threading.Tasks;

namespace DataAcquisition.Core.Interfaces
{
	public interface IDataExporter<T>
	{
		Task<bool> ExportDataAsync(IEnumerable<T> data, string destination);
	}
}