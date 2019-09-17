using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using TankyReloaded.Actors;

namespace TankyReloaded
{
    public interface IStage
    {
        IEnumerable<IStageObject> Objects { get; }
        double Width { get; }
        double Height { get; }
        void Draw(SpriteBatch spriteBatch);
        void Add(IStageObject stageObject);
        void AddRelative(IStageObject toAdd, IStageObject origin, RelativePosition relativePosition);
        void Update(GameTime gameTime);
        void Remove(IStageObject stageObject);
        void Dispose();
    }
}