using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace SuperJMN.MonoGame
{
    public interface IStage
    {
        IEnumerable<IStageObject> Objects { get; }
        double Width { get; }
        double Height { get; }
        void Draw(SpriteBatch spriteBatch);
        void Add(IStageObject stageObject);
        void AddRelative(IStageObject toAdd, IStageObject guide, RelativePosition relativePosition);
        void Update(GameTime gameTime);
        void Remove(IStageObject stageObject);
        void Dispose();
    }
}