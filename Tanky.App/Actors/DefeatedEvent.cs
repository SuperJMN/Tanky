using SuperJMN.MonoGame;

namespace TankyApp.Actors
{
    internal class DefeatedEvent
    {
        public IStageObject Winner { get; }
        public IStageObject Defeated { get; }

        public DefeatedEvent(IStageObject winner, IStageObject defeated)
        {
            Winner = winner;
            Defeated = defeated;
        }
    }
}