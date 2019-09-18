namespace TankyReloaded.Actors
{
    public interface IReadonlyRectangle
    {
        double Left { get; }
        double Top { get; }
        double Width { get; }
        double Height { get; }
    }
}